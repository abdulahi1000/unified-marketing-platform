
/*
    Tables
*/
WITH all_ad_stats AS (
    SELECT * FROM {{ ref('stg_facebook_ads_stats') }}
),
/*
    Formatted
*/
formatted AS (
    SELECT
        -- FK
        ad_id,
        account_id,

        -- Metrics
        ad_spend,
        ad_impressions,
        ad_clicks,

        -- Metadata
        ad_date,
        'facebook_ads' AS data_src,

        -- Calculated metrics
        ad_clicks / NULLIF(ad_impressions, 0) AS ad_ctr,
        ad_spend / NULLIF(ad_clicks, 0) AS ad_cpc,
        ad_spend / NULLIF(ad_impressions, 0) * 1000 AS ad_cpm
    FROM
        all_ad_stats 
)
SELECT * FROM formatted
