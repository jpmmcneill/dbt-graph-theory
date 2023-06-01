{% macro array_agg(field, distinct=false, order_field=none, order=none) %}
    {{ return(adapter.dispatch("array_agg", macro_namespace="dbt_graph_theory")(field, distinct, order_field, order)) }}
{% endmacro %}

{% macro snowflake__array_agg(field, distinct, order_field, order) %}
    array_agg({{ "distinct" if distinct }} {{ field }}) {{ "within group (order by " ~ order_field ~ " " ~ order ~ ")" if order_field }}
{% endmacro %}

{% macro postgres__array_agg(field, distinct, order_field, order) %}
    {# nulls are removed from the array to keep it alligned with the snowflake implementation #}
    array_remove(array_agg({{ "distinct" if distinct }} {{ field }} {{ "order by " ~ order_field ~ " " ~ order if order_field }}), null)
{% endmacro %}

{% macro bigquery__array_agg(field, distinct, order_field, order) %}
    {# nulls are removed from the array to keep it alligned with the snowflake implementation #}
    array_agg({{'distinct' if distinct}} {{field}} ignore nulls {{ "order by " ~ order_field ~ " " ~ order if order_field }})
{% endmacro %}

{% macro duckdb__array_agg(field, distinct, order_field, order) %}
    list({{ "distinct" if distinct }} {{ field }} {{ "order by " ~ order_field ~ " " ~ order if order_field }})
{% endmacro %}

{% macro default__array_agg(field, distinct, order_field, order) %}
    {{ dbt_graph_theory.adapter_missing_exception() }}
{% endmacro %}
