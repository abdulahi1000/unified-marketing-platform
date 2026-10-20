/*
    Tables
*/
WITH all_ads AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_facebook_ads_details'),
            ref('int_snapchat_ads_details')
        ],
        source_column_name=none
    ) }}
),

/*
    Formatted
*/
formatted AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['data_src', 'ad_id']) }} AS ad_key,
        ad_id,
        ad_group_id,
        campaign_id,
        account_id,
        ad_name,
        ad_status,
        ad_group_name,
        campaign_name,
        account_name,
        channel_name,
        ad_detail_updated_at,
        data_src
    FROM all_ads
)

SELECT * FROM formatted
