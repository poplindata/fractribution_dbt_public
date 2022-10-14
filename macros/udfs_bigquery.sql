{% macro create_udfs() %}

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



{% set trim_long_path %}
-- Returns the last path_lookback_steps channels in the path if path_lookback_steps > 0,
-- or the full path otherwise.
CREATE OR REPLACE FUNCTION {{ target.dataset }}.TrimLongPath(path ARRAY<STRING>, path_lookback_steps INT64) RETURNS ARRAY<STRING> LANGUAGE js AS """
if (path_lookback_steps > 0) {
    return path.slice(Math.max(0, path.length - path_lookback_steps));
  }
  return path;
"""
{% endset %}


# Functions for applying transformations to path arrays.
-- unique: Identity transform.
--   E.g. [D, A, B, B, C, D, C, C] --> [D, A, B, B, C, D, C, C].
-- exposure: Collapse sequential repeats.
--   E.g. [D, A, B, B, C, D, C, C] --> [D, A, B, C, D, C].
-- first: Removes repeated events.
--   E.g. [D, A, B, B, C, D, C, C] --> [D, A, B, C].
-- frequency: Removes repeat events but tracks them with a count.
--   E.g. [D, A, B, B, C, D, C, C] --> [D(2), A(1), B(2), C(3)).


{% set remove_if_not_all %}
-- Returns the path with all copies of targetElem removed, unless the path consists only of
-- targetElems, in which case the original path is returned.
CREATE OR REPLACE FUNCTION {{ target.dataset }}.RemoveIfNotAll(path ARRAY<STRING>, targetElem STRING)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  var transformedPath = [];
  for (var i = 0; i < path.length; i++) {
    if (path[i] !== targetElem) {
      transformedPath.push(path[i]);
    }
  }
  if (!transformedPath.length) {
    return path;
  }
  return transformedPath;
""";
{% endset %}

{% set remove_if_last_and_not_all %}
-- Returns the path with all copies of targetElem removed from the tail, unless the path consists
-- only of targetElems, in which case the original path is returned.
CREATE OR REPLACE FUNCTION {{ target.dataset }}.RemoveIfLastAndNotAll(path ARRAY<STRING>, targetElem STRING)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  var tailIndex = path.length;
  for (var i = path.length - 1; i >= 0; i = i - 1) {
    if (path[i] != targetElem) {
      break;
    }
    tailIndex = i;
  }
  if (tailIndex > 0) {
    return path.slice(0, tailIndex);
  }
  return path;
""";
{% endset %}

{% set unique %}
-- Returns the unique/identity transform of the given path array.
-- E.g. [D, A, B, B, C, D, C, C] --> [D, A, B, B, C, D, C, C].
CREATE OR REPLACE FUNCTION {{ target.dataset }}.Unique(path ARRAY<STRING>)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  return path;
""";
{% endset %}

{% set exposure %}
-- Returns the exposure transform of the given path array.
-- Sequential duplicates are collapsed.
-- E.g. [D, A, B, B, C, D, C, C] --> [D, A, B, C, D, C].
CREATE OR REPLACE FUNCTION {{ target.dataset }}.Exposure(path ARRAY<STRING>)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  var transformedPath = [];
  for (var i = 0; i < path.length; i++) {
    if (i == 0 || path[i] != path[i-1]) {
      transformedPath.push(path[i]);
    }
  }
  return transformedPath;
""";
{% endset %}

{% set first %}
-- Returns the first transform of the given path array.
-- Repeated channels are removed.
-- E.g. [D, A, B, B, C, D, C, C] --> [D, A, B, C].
CREATE OR REPLACE FUNCTION {{ target.dataset }}.First(path ARRAY<STRING>)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  var transformedPath = [];
  var channelSet = new Set();
  for (const channel of path) {
    if (!channelSet.has(channel)) {
      transformedPath.push(channel);
      channelSet.add(channel)
    }
  }
  return transformedPath;
""";
{% endset %}

{% set frequency %}
-- Returns the frequency transform of the given path array.
-- Repeat events are removed, but tracked with a count.
-- E.g. [D, A, B, B, C, D, C, C] --> [D(2), A(1), B(2), C(3)].
CREATE OR REPLACE FUNCTION {{ target.dataset }}.Frequency(path ARRAY<STRING>)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  var channelToCount = {};
  for (const channel of path) {
    if (!(channel in channelToCount)) {
      channelToCount[channel] = 1
    } else {
      channelToCount[channel] +=1
    }
  }
  var transformedPath = [];
  for (const channel of path) {
    count = channelToCount[channel];
    if (count > 0) {
      transformedPath.push(channel + '(' + count.toString() + ')');
      // Reset count to 0, since the output has exactly one copy of each event.
      channelToCount[channel] = 0;
    }
  }
  return transformedPath;
""";
{% endset %}


-- create the udfs (as permanent UDFs)

{% do run_query(trim_long_path) %};
{% do run_query(remove_if_not_all) %};
{% do run_query(remove_if_last_and_not_all) %};
{% do run_query(unique) %};
{% do run_query(exposure) %};
{% do run_query(first) %};
{% do run_query(frequency) %};

{% endmacro %}