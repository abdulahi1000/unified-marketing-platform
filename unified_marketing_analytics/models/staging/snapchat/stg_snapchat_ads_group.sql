with source as (
    select *   from {{ source('snapchat_ads', 'snapchat_ads_group_names') }}
),

formatted as (
    select
    -- Key
        cast(ad_group_id as string) as ad_group_id,
        cast(campaign_id as string) as campaign_id,
        cast(_surrogate_key as string) as _surrogate_key,
    
    -- Details
        cast(ad_group_name as string) as ad_group_name,
        
    -- Metadata
        CAST(ad_group_updated_at AS TIMESTAMP) AS ad_group_updated_at
    from source
)

select * from formatted

