{% macro array_construct(components) %}
    {{ return(adapter.dispatch("array_construct", macro_namespace="dbt_graph_theory")(components)) }}
{% endmacro %}

{% macro snowflake__array_construct(components) %}
    array_construct({{ components|join(",") }})
{% endmacro %}

{% macro postgres__array_construct(components) %}
    array[{{ components|join(",") }}]
{% endmacro %}

{% macro bigquery__array_construct(components) %}
    [{{ components|join(",") }}]
{% endmacro %}

{% macro duckdb__array_construct(components) %}
    list_value({{ components|join(",") }})
{% endmacro %}

{% macro default__array_construct(components) %}
    {{ dbt_graph_theory.adapter_missing_exception() }}
{% endmacro %}
