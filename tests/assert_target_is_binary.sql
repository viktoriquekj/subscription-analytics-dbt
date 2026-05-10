select * from {{ ref('fct_churn_features') }}
where has_churned not in (0, 1)