with source as (
    select *   from {{ source('facebook_ads', 'facebook_adgroup') }}
),

formatted as (
    select
    -- Key
        cast(ad_group_id as string) as ad_group_id,
    
    -- Details
        cast(ad_group_name as string) as ad_group_name,
        
    -- Metadata
        CAST(ad_group_updated_at AS TIMESTAMP) AS ad_group_updated_at
    from source
)

select * from formatted

