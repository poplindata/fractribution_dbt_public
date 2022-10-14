{% macro channel_classification() %}
-- macro to perform channel classifications
-- each channel should return a name
-- that will also be a valid BigQuery column name
-- by convention use underscores to separate
-- (<300 characters, avoid spaces, leading numbers)

CASE
    WHEN
        LOWER(mkt_medium) IN ('cpc', 'ppc')
        AND REGEXP_CONTAINS(LOWER(mkt_campaign), r'brand')
        THEN 'Paid_Search_Brand'
    WHEN
        LOWER(mkt_medium) IN ('cpc', 'ppc')
        AND REGEXP_CONTAINS(LOWER(mkt_campaign), r'generic')
        THEN 'Paid_Search_Generic'
    WHEN
        LOWER(mkt_medium) IN ('cpc', 'ppc')
        AND NOT REGEXP_CONTAINS(LOWER(mkt_campaign), r'brand|generic')
        THEN 'Paid_Search_Other'
    WHEN LOWER(mkt_medium) = 'organic' THEN 'Organic_Search'
    WHEN
        LOWER(mkt_medium) IN ('display', 'cpm', 'banner')
        AND REGEXP_CONTAINS(LOWER(mkt_campaign), r'prospect')
        THEN 'Display_Prospecting'
    WHEN
        LOWER(mkt_medium) IN ('display', 'cpm', 'banner')
        AND REGEXP_CONTAINS(
            LOWER(mkt_campaign),
            r'retargeting|re-targeting|remarketing|re-marketing')
        THEN 'Display_Retargeting'
    WHEN
        LOWER(mkt_medium) IN ('display', 'cpm', 'banner')
        AND NOT REGEXP_CONTAINS(
            LOWER(mkt_campaign),
            r'prospect|retargeting|re-targeting|remarketing|re-marketing')
        THEN 'Display_Other'
    WHEN
        REGEXP_CONTAINS(LOWER(mkt_campaign), r'video|youtube')
        OR REGEXP_CONTAINS(LOWER(mkt_source), r'video|youtube')
        THEN 'Video'
    WHEN
        LOWER(mkt_medium) = 'social'
        AND REGEXP_CONTAINS(LOWER(mkt_campaign), r'prospect')
        THEN 'Paid_Social_Prospecting'
    WHEN
        LOWER(mkt_medium) = 'social'
        AND REGEXP_CONTAINS(
            LOWER(mkt_campaign),
            r'retargeting|re-targeting|remarketing|re-marketing')
        THEN 'Paid_Social_Retargeting'
    WHEN
        LOWER(mkt_medium) = 'social'
        AND NOT REGEXP_CONTAINS(
            LOWER(mkt_campaign),
            r'prospect|retargeting|re-targeting|remarketing|re-marketing')
        THEN 'Paid_Social_Other'
    WHEN mkt_source = '(direct)' THEN 'Direct'
    WHEN LOWER(mkt_medium) = 'referral' THEN 'Referral'
    WHEN LOWER(mkt_medium) = 'email' THEN 'Email'
    WHEN
        LOWER(mkt_medium) IN ('cpc', 'ppc', 'cpv', 'cpa', 'affiliates')
        THEN 'Other_Advertising'
    ELSE 'Unmatched_Channel'
END
{% endmacro %}