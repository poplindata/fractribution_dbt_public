# Copyright 2022 Google LLC..
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    SELECT ARRAY_AGG(DISTINCT channel) AS c FROM {{ ref('channel_counts') }}
)
SELECT * FROM UNNEST((SELECT c FROM channels)) AS channel, UNNEST([10000]) AS spend