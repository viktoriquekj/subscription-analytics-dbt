with source as (

    select * from {{ source('telco', 'raw_telco_customers') }}

),

cleaned as (

    select
        customerid                                      as customer_id,

        lower(gender)                                   as gender,
        cast(seniorcitizen as boolean)                  as is_senior_citizen,
        lower(partner)                                  as has_partner,
        lower(dependents)                               as has_dependents,

        cast(tenure as integer)                         as tenure_months,

        lower(contract)                                 as contract_type,
        lower(paperlessbilling)                         as has_paperless_billing,
        lower(paymentmethod)                            as payment_method,

        cast(monthlycharges as decimal(10,2))           as monthly_charges,
        cast(totalcharges as decimal(10,2))             as total_charges,

        lower(phoneservice)                             as has_phone_service,
        lower(multiplelines)                            as multiple_lines,
        lower(internetservice)                          as internet_service,
        lower(onlinesecurity)                           as has_online_security,
        lower(onlinebackup)                             as has_online_backup,
        lower(deviceprotection)                         as has_device_protection,
        lower(techsupport)                              as has_tech_support,
        lower(streamingtv)                              as has_streaming_tv,
        lower(streamingmovies)                          as has_streaming_movies,

        case when lower(churn) = 'yes' then 1
             else 0 end                                 as has_churned

    from source

)

select * from cleaned