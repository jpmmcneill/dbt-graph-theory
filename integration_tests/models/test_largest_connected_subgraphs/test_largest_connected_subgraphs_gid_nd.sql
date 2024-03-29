with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_gid_nd_data'),
        graph_id='graph_id'
    ) }}
),

required as (
    select v.* from (
        values
        (
            cast(null as {{ type_string() }}),
            cast(null as {{ type_string() }}),
            cast(null as {{ type_string() }}),
            array[null]
        )
    ) as v (graph_id, vertex, subgraph_id, subgraph_members)
    where false
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["graph_id", "vertex", "subgraph_id", "subgraph_members"]
) }}
