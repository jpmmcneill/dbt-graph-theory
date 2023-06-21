{% macro reduce_join(input, vertex_1 = "vertex_1", vertex_2 = "vertex_2") %}
    {#
        This macro takes two columns (vertex_1 and vertex_2), interprets them as the result of a join and
        attempts to establish a 1-1 relationship between the two, taking the entire join into account and
        preserving as much information as possible. This is analagous to a matching problem.

        Parameters:
        input - Union[string, ref()]: The input model or CTE that follows the structure above.
        vertex_1 - Optional[string]: The field name corresponding to the "first" field vertex. Default = "vertex_1"
        vertex_2 - Optional[string]: The field name corresponding to the "second" field vertex. Default = "vertex_2"
    #}

with recursive prepare as (
    select distinct
        {{ vertex_1 }} as vertex_1,
        {{ vertex_2 }} as vertex_2
    from
        {{ input }}
),

generate_count as (
    select
        vertex_1,
        vertex_2,
        count(vertex_1) over (partition by vertex_2) as _count
    from prepare
),

working as (
    select
        vertex_1,
        vertex_2,
        _count,
        false as remove,
        [concat(vertex_1, vertex_2)] as _edges
    from generate_count
    where _count = 1

    union all

    select
        main.vertex_1,
        main.vertex_2,
        main._count,
        not working.remove as remove,
        list_append(working._edges, concat(main.vertex_1, main.vertex_2)) as _edges
    from generate_count as main
    inner join working on (
        (
            working.vertex_1 = main.vertex_1 and
            working.vertex_2 != main.vertex_2
        ) or (
            working.vertex_1 != main.vertex_1 and
            working.vertex_2 = main.vertex_2
        )
    ) and not list_contains(working._edges, concat(main.vertex_1, main.vertex_2))
)

select distinct
    vertex_1 as {{ vertex_1 }},
    vertex_2 as {{ vertex_2 }}
from working
where not remove

{% endmacro %}
