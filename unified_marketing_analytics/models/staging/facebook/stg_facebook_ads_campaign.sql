with source as (
    select *   from {{ source('facebook_ads', 'facebook_campaign') }}
),

formatted as (
    select
    -- Key
        cast(campaign_id as string) as campaign_id,
    
    -- Details
        cast(campaign_name as string) as campaign_name,
        
    -- Metadata
        CAST(campaign_updated_at AS TIMESTAMP) AS campaign_updated_at
    from source
)

select * from formatted
