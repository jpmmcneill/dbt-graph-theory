{% macro set_union(distinct=true) %}
    {{ return(adapter.dispatch("set_union", macro_namespace="dbt_graph_theory")(distinct)) }}
{% endmacro %}

{% macro bigquery__set_union(distinct) %}
    {{ 'union distinct' if distinct else 'union all' }}
{% endmacro %}

{% macro default__set_union(distinct) %}
    {{ 'union' if distinct else 'union all' }}
{% endmacro %}
