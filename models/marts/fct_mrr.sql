with subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

-- calculate MRR grouped by month and plan
mrr_by_month as (
    select
        date_trunc('month', start_date) as month,
        plan,
        count(*)                        as subscription_count,
        sum(mrr)                        as total_mrr,
        sum(case when is_active then mrr else 0 end)    as active_mrr,
        sum(case when not is_active then mrr else 0 end) as churned_mrr

    from subscriptions
    group by 1, 2
)

select * from mrr_by_month
order by month, plan