with stg as (

    select * from {{ ref('stg_customers') }}

)

select
    customer_id,
    gender,
    is_senior_citizen,
    has_partner,
    has_dependents,
    contract_type,
    payment_method,
    internet_service,
    has_churned
from stg