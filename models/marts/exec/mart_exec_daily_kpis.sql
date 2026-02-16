{{
  config(
    materialized='incremental',
    unique_key='date',
    partition_by={'field': 'date', 'data_type': 'date'},
    cluster_by=['date']
  )
}}

with sessions as (
    select
        date_day as date,
        sum(sessions) as sessions,
        sum(engaged_sessions) as engaged_sessions
    from {{ ref('fct_ga4__sessions_daily') }}
    {% if is_incremental() %}
      where date_day >= (select coalesce(max(date), date('1970-01-01')) from {{ this }})
    {% endif %}
    group by 1
),
purchases as (
    select
        event_date_dt as date,
        sum(purchase_revenue) as revenue,
        count(distinct transaction_id) as orders,
        count(distinct user_pseudo_id) as purchasers,
        sum(items_purchased) as items_sold
    from {{ ref('fct_ga4__purchases') }}
    {% if is_incremental() %}
      where event_date_dt >= (select coalesce(max(date), date('1970-01-01')) from {{ this }})
    {% endif %}
    group by 1
)
select
    coalesce(s.date, p.date) as date,
    coalesce(p.revenue, 0) as revenue,
    coalesce(p.orders, 0) as orders,
    coalesce(p.purchasers, 0) as purchasers,
    case when coalesce(p.orders, 0) = 0 then 0 else coalesce(p.revenue, 0) / p.orders end as aov,
    coalesce(s.sessions, 0) as sessions,
    coalesce(s.engaged_sessions, 0) as engaged_sessions,
    case when coalesce(s.sessions, 0) = 0 then 0 else coalesce(p.orders, 0) / s.sessions end as conversion_rate,
    coalesce(p.items_sold, 0) as items_sold
from sessions s
full outer join purchases p on s.date = p.date
