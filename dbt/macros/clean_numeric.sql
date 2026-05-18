{% macro clean_numeric(column) %}
CASE
  WHEN lower(trim({{ column }})) = 'nan' THEN NULL
  ELSE NULLIF(REPLACE(REPLACE(REPLACE({{ column }}, '$', ''), ' USD', ''), ',', '.'), '')::float
END
{% endmacro %}
