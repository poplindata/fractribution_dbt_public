-- User supplied SQL script to extract total ad spend by channel.
--
-- Required output schema:
--  channel: STRING NOT NULL (Must match those in channel_definitions.sql.)
--  spend: FLOAT64 (Use the same monetary units as conversion revenue, and NULL if unknown.)
--
-- Note that all flags are passed into this template (e.g. conversion_window_start/end_date).


-- TODO: put in your own spend calculations per channel here
-- the model below assigns an example 10k spend to each channel
-- found in channel_counts

WITH channels AS (
    SELECT ARRAY_AGG(DISTINCT channel) AS c FROM {{ ref('s_channel_counts') }}
)
SELECT
CAST(channel.value AS STRING) AS channel,
10000 AS spend
FROM
channels,
LATERAL FLATTEN(c) channel