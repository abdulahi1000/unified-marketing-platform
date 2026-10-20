/*
    Tables
*/
WITH all_ad_stats AS (
    SELECT * FROM {{ ref('stg_snapchat_ads_stats') }}
),

ad_details AS (
    SELECT
        ad_id,
        account_id
    FROM {{ ref('int_snapchat_ads_details') }}
),

/*
    Formatted
*/
formatted AS (
    SELECT
        -- FK
        all_ad_stats.ad_detail_id AS ad_id,
        ad_details.account_id,

        -- Dimensions
        all_ad_stats.ad_country,
        all_ad_stats.ad_currency_code,

        -- Measures
        all_ad_stats.ad_spend,
        all_ad_stats.ad_impressions,
        all_ad_stats.ad_clicks,

        -- Metadata
        all_ad_stats.ad_date,
        all_ad_stats.data_src,

        -- Calculated metrics
        all_ad_stats.ad_clicks / NULLIF(all_ad_stats.ad_impressions, 0) AS ad_ctr,
        all_ad_stats.ad_spend / NULLIF(all_ad_stats.ad_clicks, 0) AS ad_cpc,
        all_ad_stats.ad_spend / NULLIF(all_ad_stats.ad_impressions, 0) * 1000 AS ad_cpm
    FROM all_ad_stats
    LEFT JOIN ad_details
        ON all_ad_stats.ad_detail_id = ad_details.ad_id
)

SELECT * FROM formatted
