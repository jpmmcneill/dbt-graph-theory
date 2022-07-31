{% macro cte_difference(cte_1, cte_2, fields=[]) %}
(
    select '{{cte_1}}' as _data_location, {{ fields|join(', ') }} from {{ cte_1 }}
    except
    select '{{cte_1}}' as _data_location, {{ fields|join(', ') }} from {{ cte_2 }}
    union
    select '{{cte_2}}' as _data_location, {{ fields|join(', ') }} from {{ cte_2 }}
    except
    select '{{cte_2}}' as _data_location, {{ fields|join(', ') }} from {{ cte_1 }}
) as diff
{% endmacro %}
