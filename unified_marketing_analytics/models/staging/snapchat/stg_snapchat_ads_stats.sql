with source AS (
    SELECT * from {{source('snapchat_ads', 'snapchat_ads_stats')}}
),


formatted AS (

    SELECT
        -- FK
        CAST(ad_detail_id AS STRING) AS ad_detail_id,
        CAST(ad_country AS STRING) AS ad_country,

        -- Dimensions
        CAST(ad_currency_code AS STRING) AS ad_currency_code,

        -- Measures
        CAST(ad_spend AS DOUBLE) AS ad_spend,
        TRY_CAST(ad_impressions AS INTEGER) AS ad_impressions,
        TRY_CAST(ad_clicks AS INTEGER) AS ad_clicks,
        CAST(data_src AS STRING) AS data_src,

        -- Metadata
        CAST(ad_date AS DATE) AS ad_date
    FROM
        source
)

SELECT * FROM formatted
