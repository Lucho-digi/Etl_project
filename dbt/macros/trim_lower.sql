{% macro trim_lower(column) %}
lower(trim({{ column }}))
{% endmacro %}
