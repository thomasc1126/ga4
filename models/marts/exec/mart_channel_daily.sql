{{
  config(
    materialized='incremental',
    unique_key='date_channel_key',
    partition_by={'field': 'date', 'data_type': 'date'},
    cluster_by=['default_channel_grouping']
  )
}}

with sessions as (
    select
        date_day as date,
        default_channel_grouping,
        source,
        medium,
        sum(sessions) as sessions
    from {{ ref('fct_ga4__sessions_daily') }}
    {% if is_incremental() %}
      where date_day >= (select coalesce(max(date), date('1970-01-01')) from {{ this }})
    {% endif %}
    group by 1,2,3,4
),
purchases as (
    select
        event_date_dt as date,
        default_channel_grouping,
        source,
        medium,
        sum(purchase_revenue) as revenue,
        count(distinct transaction_id) as orders,
        count(distinct user_pseudo_id) as purchasers
    from {{ ref('fct_ga4__purchases') }}
    {% if is_incremental() %}
      where event_date_dt >= (select coalesce(max(date), date('1970-01-01')) from {{ this }})
    {% endif %}
    group by 1,2,3,4
)
select
    coalesce(s.date, p.date) as date,
    coalesce(s.default_channel_grouping, p.default_channel_grouping, 'Unassigned') as default_channel_grouping,
    coalesce(s.source, p.source, '(direct)') as source,
    coalesce(s.medium, p.medium, '(none)') as medium,
    coalesce(s.sessions, 0) as sessions,
    coalesce(p.revenue, 0) as revenue,
    coalesce(p.orders, 0) as orders,
    coalesce(p.purchasers, 0) as purchasers,
    case when coalesce(p.orders, 0) = 0 then 0 else coalesce(p.revenue, 0) / p.orders end as aov,
    case when coalesce(s.sessions, 0) = 0 then 0 else coalesce(p.orders, 0) / s.sessions end as conversion_rate,
    concat(cast(coalesce(s.date, p.date) as string), '||', coalesce(s.default_channel_grouping, p.default_channel_grouping, 'Unassigned')) as date_channel_key
from sessions s
full outer join purchases p
  on s.date = p.date
 and s.default_channel_grouping = p.default_channel_grouping
 and s.source = p.source
 and s.medium = p.medium
