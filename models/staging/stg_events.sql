with source as (
    select * from {{ source('raw', 'raw_events') }}
),

cleaned as (
    select
        event_id,
        customer_id,
        lower(event_type)              as event_type,
        cast(occurred_at as date)      as event_date
    from source
)

select * from cleaned