
SELECT
  conversions_by_customer_id.customerId,
  conversionTimestamp,
  revenue,
  ARRAY_TO_STRING({{ target.dataset }}.TrimLongPath(
    ARRAY_AGG(channel ORDER BY visitStartTimestamp), {{ var('path_lookback_steps') }}),
    ' > ') AS path,
  ARRAY_TO_STRING(
    {% for path_transform_name, _ in var('path_transforms')|reverse %}
      {{ target.dataset }}.{{path_transform_name}}(
    {% endfor %}
        ARRAY_AGG(channel ORDER BY visitStartTimestamp)
    {% for _, arg_str in var('path_transforms') %}
      {% if arg_str %}, {{arg_str}}{% endif %})
    {% endfor %}
    , ' > ') AS transformedPath
FROM {{ ref('conversions_by_customer_id') }}
LEFT JOIN {{ ref('sessions_by_customer_id') }}
  ON
    conversions_by_customer_id.customerId = sessions_by_customer_id.customerId
    AND TIMESTAMP_DIFF(conversionTimestamp, visitStartTimestamp, DAY)
      BETWEEN 0 AND {{ var('path_lookback_days') }}
GROUP BY
  customerId,
  conversionTimestamp,
  revenue