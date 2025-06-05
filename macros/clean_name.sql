{% macro clean_name(column_name) %}
    INITCAP(TRIM({{ column_name }}))
{% endmacro %}
