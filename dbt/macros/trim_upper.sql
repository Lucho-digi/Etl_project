{% macro trim_upper(column) %}
upper(trim({{ column }}))
{% endmacro %}
