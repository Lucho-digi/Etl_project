{% macro clean_future_date(column) %}
CASE WHEN {{ column }} > CURRENT_DATE THEN NULL ELSE {{ column }} END
{% endmacro %}
