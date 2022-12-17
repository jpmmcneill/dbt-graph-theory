{% macro cast_timestamp(field) %}
    {{ return(adapter.dispatch("cast_timestamp", macro_namespace="dbt_graph_theory")(field)) }}
{% endmacro %}

{% macro snowflake__cast_timestamp(field) %}
    cast({{ field }} as timestamp_ntz)
{% endmacro %}

{% macro postgres__cast_timestamp(field) %}
    cast({{ field }} as timestamp)
{% endmacro %}

{% macro default__cast_timestamp(field) %}
    {{ dbt_graph_theory.adapter_missing_exception() }}
{% endmacro %}
