with subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

customers as (
    select
        customer_id,
        min(start_date)     as first_subscription_date,
        max(mrr)            as current_mrr,
        bool_or(is_active)  as has_active_subscription,

        -- cohort = the month they first subscribed
        date_trunc('month', min(start_date)) as cohort_month

    from subscriptions
    group by customer_id
)

select * from customers