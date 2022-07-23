with computed as (
    {{ dbt_graph_theory.largest_connected_largest_connected_subgraph(
        input=ref('test_largest_connected_subgraph_no_data_data')
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        (null::integer, null::integer, null::integer, null::text, array[null])
    ) as v (id, vertex_1, vertex_2, subgraph_id, subgraph_members)
    where false
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]
) }}
