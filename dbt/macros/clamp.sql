{% macro clamp(column, min, max) %}
GREATEST({{ min }}, LEAST({{ max }}, {{ column }}))
{% endmacro %}
