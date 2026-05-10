with stg as (

    select * from {{ ref('stg_customers') }}

),

features as (

    select
        -- identifier
        customer_id,

        -- demographic features
        gender,
        is_senior_citizen,
        case when has_partner    = 'yes' then 1 else 0 end  as has_partner,
        case when has_dependents = 'yes' then 1 else 0 end  as has_dependents,

        -- contract features (strongest churn signals)
        contract_type,
        case when contract_type = 'month-to-month' then 1
             else 0 end                                      as is_month_to_month,
        case when has_paperless_billing = 'yes' then 1
             else 0 end                                      as has_paperless_billing,
        payment_method,

        -- tenure
        tenure_months,
        case
            when tenure_months < 12  then 'early'
            when tenure_months < 36  then 'established'
            else 'long-term'
        end                                                  as tenure_segment,

        -- billing (monthly_charges is safe — reflects plan, not accumulated spend)
        -- total_charges is intentionally excluded from ML features: it is a
        -- near-perfect proxy for tenure × monthly_charges and risks data leakage
        monthly_charges,

        -- internet service tier
        internet_service,
        case when internet_service = 'fiber optic' then 1
             else 0 end                                      as has_fiber,

        -- add-on services (each is an engagement signal)
        case when has_online_security  = 'yes' then 1 else 0 end  as has_online_security,
        case when has_online_backup    = 'yes' then 1 else 0 end  as has_online_backup,
        case when has_device_protection= 'yes' then 1 else 0 end  as has_device_protection,
        case when has_tech_support     = 'yes' then 1 else 0 end  as has_tech_support,
        case when has_streaming_tv     = 'yes' then 1 else 0 end  as has_streaming_tv,
        case when has_streaming_movies = 'yes' then 1 else 0 end  as has_streaming_movies,

        -- engineered: total number of active add-on services
        (
            case when has_online_security   = 'yes' then 1 else 0 end +
            case when has_online_backup     = 'yes' then 1 else 0 end +
            case when has_device_protection = 'yes' then 1 else 0 end +
            case when has_tech_support      = 'yes' then 1 else 0 end +
            case when has_streaming_tv      = 'yes' then 1 else 0 end +
            case when has_streaming_movies  = 'yes' then 1 else 0 end
        )                                                    as service_count,

        -- target variable
        has_churned

    from stg

)

select * from features