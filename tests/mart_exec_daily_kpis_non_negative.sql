select *
from {{ ref('mart_exec_daily_kpis') }}
where revenue < 0
   or orders < 0
   or purchasers < 0
   or sessions < 0
   or engaged_sessions < 0
   or items_sold < 0
