-- This test fails if any row has negative MRR.
-- dbt treats any row returned by this query as a test failure.

select
    subscription_id,
    mrr
from {{ ref('stg_subscriptions') }}
where mrr < 0