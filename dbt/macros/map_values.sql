{% macro map_values(column, mappings, default=none) %}
{% set default_expr = default if default else "lower(trim(" ~ column ~ "))" %}
CASE lower(trim({{ column }}))
  {% for old_val, new_val in mappings.items() %}
  WHEN '{{ old_val }}' THEN '{{ new_val }}'
  {% endfor %}
  ELSE {{ default_expr }}
END
{% endmacro %}
