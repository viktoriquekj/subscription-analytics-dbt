with stg as (

    select * from {{ ref('stg_customers') }}

)

select
    contract_type,
    count(*)                                            as customer_count,
    round(sum(monthly_charges), 2)                      as total_mrr,
    round(avg(monthly_charges), 2)                      as avg_mrr,
    round(sum(case when has_churned = 1
                   then monthly_charges end), 2)        as churned_mrr,
    round(sum(case when has_churned = 0
                   then monthly_charges end), 2)        as retained_mrr,
    round(avg(case when has_churned = 1
                   then 1.0 else 0.0 end) * 100, 1)    as churn_rate_pct
from stg
group by contract_type
order by total_mrr desc