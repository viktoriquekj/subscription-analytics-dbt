with source as (
    select * from {{ source('raw', 'raw_subscriptions') }}
),

cleaned as (
    select
        subscription_id,
        customer_id,
        lower(plan)         as plan,
        cast(mrr as float)  as mrr,
        lower(status)       as status,
        cast(start_date as date) as start_date,
        cast(end_date as date)   as end_date,

        -- derived flag: is subscription currently active?
        case when lower(status) = 'active' then true else false end as is_active

    from source
    where subscription_id is not null
)

select * from cleaned