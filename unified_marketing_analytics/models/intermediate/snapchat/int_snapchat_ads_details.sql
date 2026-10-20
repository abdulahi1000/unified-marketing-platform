/*
    Tables
*/
WITH ads AS (
    SELECT *
    FROM {{ ref('stg_snapchat_ads') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ad_id
        ORDER BY ad_updated_at DESC
    ) = 1
),

ad_groups AS (
    SELECT *
    FROM {{ ref('stg_snapchat_ads_group') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ad_group_id
        ORDER BY ad_group_updated_at DESC
    ) = 1
),

campaigns AS (
    SELECT *
    FROM {{ ref('stg_snapchat_ads_campaign') }}
),

/*
    Formatted
*/
formatted AS (
    SELECT
        -- Keys
        ads.ad_id,
        ads.ad_group_id,
        ad_groups.campaign_id,
        campaigns.account_id,

        -- Details
        ads.ad_name,
        ad_groups.ad_group_name,
        campaigns.campaign_name,
        'Paid Social' AS channel_name,

        -- Metadata
        GREATEST(ads.ad_updated_at, ad_groups.ad_group_updated_at) AS ad_detail_updated_at,
        'snapchat_ads' AS data_src
    FROM ads
    LEFT JOIN ad_groups
        ON ads.ad_group_id = ad_groups.ad_group_id
    LEFT JOIN campaigns
        ON ad_groups.campaign_id = campaigns.campaign_id
)

SELECT * FROM formatted
