{% macro null_if_empty(column) %}
CASE WHEN lower(trim({{ column }})) IN ('', 'na', 'n/a', 'null') THEN NULL ELSE {{ column }} END
{% endmacro %}
