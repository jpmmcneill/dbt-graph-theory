{% macro cte_difference(cte_1, cte_2, fields=[]) %}
(
    (
        select '{{cte_1}}' as _data_location, {{ fields|join(', ') }} from {{ cte_1 }}
        {{ dbt_graph_theory.set_except() }}
        select '{{cte_1}}' as _data_location, {{ fields|join(', ') }} from {{ cte_2 }}
    )
    {{ dbt_graph_theory.set_union(distinct=true) }}
    (
        select '{{cte_2}}' as _data_location, {{ fields|join(', ') }} from {{ cte_2 }}
        {{ dbt_graph_theory.set_except() }}
        select '{{cte_2}}' as _data_location, {{ fields|join(', ') }} from {{ cte_1 }}
    )
) as diff
{% endmacro %}
