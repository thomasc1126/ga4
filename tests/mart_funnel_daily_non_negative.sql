select *
from {{ ref('mart_funnel_daily') }}
where view_item_sessions < 0
   or add_to_cart_sessions < 0
   or begin_checkout_sessions < 0
   or purchase_sessions < 0
