{% macro clean_boolean(column) %}
CASE
  WHEN lower({{ column }}) IN ('true', 'yes', 'y', '1', 'si', 't') THEN true
  WHEN lower({{ column }}) IN ('false', 'no', 'n', '0', 'f') THEN false
END
{% endmacro %}
