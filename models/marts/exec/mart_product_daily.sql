{{
  config(
    materialized='incremental',
    unique_key='date_product_key',
    partition_by={'field': 'date', 'data_type': 'date'},
    cluster_by=['item_category', 'item_id']
  )
}}

with item_purchases as (
    select
        event_date_dt as date,
        item_id,
        item_name,
        item_category,
        sum(item_revenue) as item_revenue,
        sum(quantity) as quantity,
        count(distinct transaction_id) as orders_with_item
    from {{ ref('dim_ga4__items') }}
    where event_name = 'purchase'
    {% if is_incremental() %}
      and event_date_dt >= (select coalesce(max(date), date('1970-01-01')) from {{ this }})
    {% endif %}
    group by 1,2,3,4
)
select
    date,
    item_id,
    item_name,
    item_category,
    item_revenue,
    quantity,
    orders_with_item,
    concat(cast(date as string), '||', coalesce(item_id, item_name, 'unknown_item')) as date_product_key
from item_purchases
