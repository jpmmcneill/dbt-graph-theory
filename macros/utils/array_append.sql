{% macro array_append(array, new_value) %}
    {{ return(adapter.dispatch("array_append", macro_namespace="dbt_graph_theory")(array, new_value)) }}
{% endmacro %}

{% macro snowflake__array_append(array, new_value) %}
    array_append({{ array }}, {{ new_value }})
{% endmacro %}

{% macro postgres__array_append(array, new_value) %}
    array_append({{ array }}, {{ new_value }})
{% endmacro %}

{% macro bigquery__array_append(array, new_value) %}
    array_concat({{ array }}, [{{ new_value }}])
{% endmacro %}

{% macro duckdb__array_append(array, new_value) %}
    list_append({{ array }}, {{ new_value }})
{% endmacro %}

{% macro default__array_append(array, new_value) %}
    {{ dbt_graph_theory.adapter_missing_exception() }}
{% endmacro %}
