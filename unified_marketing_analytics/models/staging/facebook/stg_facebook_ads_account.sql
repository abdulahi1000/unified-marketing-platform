with source as (
    select *   from {{ source('facebook_ads', 'facebook_new_acccount') }}
),

formatted as (
    select
    -- Key
        cast(account_id as string) as account_id,
    
    -- Details
        cast(account_name as string) as account_name,
        cast(ad_currency_code as string) as ad_currency_code,
        
    -- Metadata
        cast(account_created_at as TIMESTAMP) as account_created_at,
        CAST(account_updated_at AS TIMESTAMP) AS account_updated_at
    from source
)

select * from formatted
