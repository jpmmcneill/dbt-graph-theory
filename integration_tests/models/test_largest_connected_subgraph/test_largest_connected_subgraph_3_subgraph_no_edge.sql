with computed as (
    {{ dbt_graph_theory.largest_connected_largest_connected_subgraph(
        input=ref('test_largest_connected_subgraph_3_subgraph_no_edge_data')
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        ('A', '1', array['A']),
        ('B', '2', array['B']),
        ('C', '3', array['C'])
    ) as v (vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
