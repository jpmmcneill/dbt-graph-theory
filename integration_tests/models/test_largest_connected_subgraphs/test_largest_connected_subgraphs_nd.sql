with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_nd_data')
    ) }}
),

required as (
    select v.* from (
        values
        (cast(null as text), cast(null as text), array[null])
    ) as v (vertex, subgraph_id, subgraph_members)
    where false
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
