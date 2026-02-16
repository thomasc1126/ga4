{{
  config(
    materialized='incremental',
    unique_key='date',
    partition_by={'field': 'date', 'data_type': 'date'},
    cluster_by=['date']
  )
}}

with funnel_events as (
    select
        event_date_dt as date,
        count(distinct case when event_name = 'view_item' then session_key end) as view_item_sessions,
        count(distinct case when event_name = 'add_to_cart' then session_key end) as add_to_cart_sessions,
        count(distinct case when event_name = 'begin_checkout' then session_key end) as begin_checkout_sessions,
        count(distinct case when event_name = 'purchase' then session_key end) as purchase_sessions
    from {{ ref('stg_ga4__events') }}
    where event_name in ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
    {% if is_incremental() %}
      and event_date_dt >= (select coalesce(max(date), date('1970-01-01')) from {{ this }})
    {% endif %}
    group by 1
)
select
    date,
    view_item_sessions,
    add_to_cart_sessions,
    begin_checkout_sessions,
    purchase_sessions,
    case when view_item_sessions = 0 then 0 else add_to_cart_sessions / view_item_sessions end as cvr_view_to_cart,
    case when add_to_cart_sessions = 0 then 0 else begin_checkout_sessions / add_to_cart_sessions end as cvr_cart_to_checkout,
    case when begin_checkout_sessions = 0 then 0 else purchase_sessions / begin_checkout_sessions end as cvr_checkout_to_purchase,
    case when view_item_sessions = 0 then 0 else purchase_sessions / view_item_sessions end as cvr_view_to_purchase
from funnel_events
