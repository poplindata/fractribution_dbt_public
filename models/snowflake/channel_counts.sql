SELECT
    channel,
    campaign,
    source,
    medium,
    COUNT(*) AS number_of_events
FROM
    {{ ref('s_sessions_by_customer_id') }}
GROUP BY channel, campaign, source, medium
ORDER BY channel, number_of_events DESC