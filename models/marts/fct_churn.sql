with subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

events as (
    select * from {{ ref('stg_events') }}
),

-- get only cancellation events
cancellations as (
    select
        customer_id,
        event_date as cancelled_at
    from events
    where event_type = 'cancel'
),

-- join subscriptions with their cancellation event
churn as (
    select
        s.subscription_id,
        s.customer_id,
        s.plan,
        s.mrr,
        s.start_date,
        c.cancelled_at,

        -- how many days was the customer active before churning?
        datediff('day', s.start_date, c.cancelled_at) as days_active_before_churn,

        -- which month did the churn happen?
        date_trunc('month', c.cancelled_at)            as churn_month

    from subscriptions s
    inner join cancellations c
        on s.customer_id = c.customer_id
)

select * from churn