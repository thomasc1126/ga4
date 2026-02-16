select *
from {{ ref('mart_product_daily') }}
where item_revenue < 0
   or quantity < 0
   or orders_with_item < 0
