{% test value_in_range(model, column_name, min_value=none, max_value=none) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} IS NOT NULL
  AND (
    {% if min_value is not none %}{{ column_name }} < {{ min_value }}{% endif %}
    {% if min_value is not none and max_value is not none %} OR {% endif %}
    {% if max_value is not none %}{{ column_name }} > {{ max_value }}{% endif %}
  )

{% endtest %}
