with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_gid_nd_data'),
        graph_id='graph_id'
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        (null::text, null::text, null::text, array[null])
    ) as v (graph_id, vertex, subgraph_id, subgraph_members)
    where false
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["graph_id", "vertex", "subgraph_id", "subgraph_members"]
) }}
