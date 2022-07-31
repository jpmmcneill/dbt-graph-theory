{% macro array_contains(array, value) %}
    {{ return(adapter.dispatch("array_contains", macro_namespace="dbt_graph_theory")(array, value)) }}
{% endmacro %}

{% macro snowflake__array_contains(array, value) %}
    array_contains(cast({{ value }} as variant), {{ array }})
{% endmacro %}

{% macro postgres__array_contains(array, value) %}
    {{ value }} = any({{ array }})
{% endmacro %}

{% macro default__array_contains(array, value) %}
    {{ exceptions.raise_compiler_error("dbt-graph-theory only supports postgres and snowflake databases") }}
{% endmacro %}
