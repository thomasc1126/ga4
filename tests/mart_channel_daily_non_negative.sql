select *
from {{ ref('mart_channel_daily') }}
where sessions < 0
   or revenue < 0
   or orders < 0
   or purchasers < 0
