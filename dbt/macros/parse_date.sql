{% macro parse_date(column) %}
CASE
  WHEN {{ column }} ~ '^\d{4}-\d{2}-\d{2}$' THEN {{ column }}::date
  WHEN {{ column }} ~ '^\d{8}$' THEN to_date({{ column }}, 'YYYYMMDD')
  WHEN {{ column }} IS NOT NULL AND {{ column }} != '' AND REPLACE({{ column }}, '-', '/') ~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN
    CASE
      WHEN SPLIT_PART(REPLACE({{ column }}, '-', '/'), '/', 1)::int > 12 THEN to_date(REPLACE({{ column }}, '-', '/'), 'DD/MM/YYYY')
      WHEN SPLIT_PART(REPLACE({{ column }}, '-', '/'), '/', 2)::int > 12 THEN to_date(REPLACE({{ column }}, '-', '/'), 'MM/DD/YYYY')
      ELSE to_date(REPLACE({{ column }}, '-', '/'), 'MM/DD/YYYY')
    END
END
{% endmacro %}
