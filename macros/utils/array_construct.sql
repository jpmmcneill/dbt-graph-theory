{% macro array_construct(components) %}
    {{ return(adapter.dispatch("array_construct", macro_namespace="dbt_graph_theory")(components)) }}
{% endmacro %}

{% macro snowflake__array_construct(components) %}
    array_construct({{ components|join(",") }})
{% endmacro %}

{% macro postgres__array_construct(components) %}
    array[{{ components|join(",") }}]
{% endmacro %}

{% macro default__array_construct(components) %}
    {{ exceptions.raise_compiler_error("dbt-graph-theory only supports the postgres and snowflake adapters") }}
{% endmacro %}
