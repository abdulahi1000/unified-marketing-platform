/*
    Tables
*/
WITH
all_stats AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_facebook_ads_stats'),
            ref('int_snapchat_ads_stats')
        ],
        source_column_name=none
    ) }}
),

/*
    Formatted
*/
formatted AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['all_stats.data_src', 'all_stats.ad_id']) }} AS ad_key,
        all_stats.ad_id,
        all_stats.account_id,
        all_stats.ad_country,
        all_stats.ad_currency_code,
        all_stats.ad_date,
        all_stats.data_src,

        -- Measures
        all_stats.ad_spend,
        all_stats.ad_impressions,
        all_stats.ad_clicks,
        all_stats.ad_ctr,
        all_stats.ad_cpc,
        all_stats.ad_cpm
    FROM all_stats
)

SELECT * FROM formatted
