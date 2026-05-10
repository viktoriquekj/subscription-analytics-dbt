
select customer_id, count(*) as n
from {{ ref('fct_churn_features') }}
group by customer_id
having n > 1