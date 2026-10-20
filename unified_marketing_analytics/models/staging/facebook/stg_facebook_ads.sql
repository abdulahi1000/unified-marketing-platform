with source as (
    select *   from {{ source('facebook_ads', 'facebook_ads') }}
),

formatted as (
    select
    -- Key
        cast(ad_id as string) as ad_id,
        cast(campaign_id as string) as campaign_id,
        cast(ad_group_id as string) as ad_group_id,
        cast(account_id as string) as account_id,
    
    -- Details
        cast(ad_name as string) as ad_name,
        cast(ad_status as string) as ad_status,
        
    -- Metadata
        CAST(ad_updated_at AS TIMESTAMP) AS ad_updated_at
    from source
)

select * from formatted
