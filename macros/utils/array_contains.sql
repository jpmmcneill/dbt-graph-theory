{% macro array_contains(array, value) %}
    {{ return(adapter.dispatch("array_contains", macro_namespace="dbt_graph_theory")(array, value)) }}
{% endmacro %}

{% macro snowflake__array_contains(array, value) %}
    array_contains(cast({{ value }} as variant), {{ array }})
{% endmacro %}

{% macro postgres__array_contains(array, value) %}
    {{ value }} = any({{ array }})
{% endmacro %}

{% macro bigquery__array_contains(array, value) %}
    ({{ value }} in unnest({{array}}))
{% endmacro %}

{% macro duckdb__array_contains(array, value) %}
    list_contains({{ array }}, {{ value }})
{% endmacro %}

{% macro default__array_contains(array, value) %}
    {{ dbt_graph_theory.adapter_missing_exception() }}
{% endmacro %}
