{% macro union(distinct=true) %}
    {{ return(adapter.dispatch("union", macro_namespace="dbt_graph_theory")(distinct)) }}
{% endmacro %}

{% macro bigquery__union(distinct) %}
    {{ 'union distinct' if distinct else 'union all' }}
{% endmacro %}

{% macro default__union(distinct) %}
    {{ 'union' if distinct else 'union all' }}
{% endmacro %}
