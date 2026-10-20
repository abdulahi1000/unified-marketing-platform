with source as (
    select *   from {{ source('snapchat_ads', 'snapchat_ad_names') }}
),

formatted as (
    select
    -- Key
        cast(ad_id as string) as ad_id,
        cast(ad_group_id as string) as ad_group_id,
    
    -- Details
        cast(ad_name as string) as ad_name,
        
    -- Metadata
        CAST(ad_detail_updated_at AS TIMESTAMP) AS ad_updated_at
    from source
)

select * from formatted
