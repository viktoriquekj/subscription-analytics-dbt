select * from {{ ref('fct_churn_features') }}
where
    customer_id        is null or
    tenure_months      is null or
    monthly_charges    is null or
    contract_type      is null or
    service_count      is null or
    has_churned        is null