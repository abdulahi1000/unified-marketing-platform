with source as (
    select *   from {{ source('snapchat_ads', 'snapchat_ads_campaign_names') }}
),

formatted as (
    select
    -- Key
        cast(campaign_id as string) as campaign_id,
        cast(account_id as string) as account_id,
    
    -- Details
        cast(campaign_name as string) as campaign_name
        
    -- Metadata

    from source
)

select * from formatted
