{% macro array_append(array, new_value) %}
    {{ return(adapter.dispatch("array_append", macro_namespace="dbt_graph_theory")(array, new_value)) }}
{% endmacro %}

{% macro snowflake__array_append(array, new_value) %}
    array_append({{ array }}, {{ new_value }})
{% endmacro %}

{% macro postgres__array_append(array, new_value) %}
    array_append({{ array }}, {{ new_value }})
{% endmacro %}

{% macro default__array_append(array, new_value) %}
    {{ exceptions.raise_compiler_error("dbt-graph-theory only supports the postgres and snowflake adapters") }}
{% endmacro %}
