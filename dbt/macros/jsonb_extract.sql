{% macro jsonb_extract(json_column, path) %}
{% set parts = path.split('.') %}
{% if parts | length == 1 %}
{{ json_column }}::jsonb->>'{{ parts[0] }}'
{% else %}
{{ json_column }}::jsonb{% for part in parts[:-1] %}->'{{ part }}'{% endfor %}->>'{{ parts[-1] }}'
{% endif %}
{% endmacro %}
