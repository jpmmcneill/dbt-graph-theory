with computed as (
    {{ dbt_graph_theory.largest_connected_largest_connected_subgraph(
        input=ref('test_largest_connected_subgraph_1_subgraph_data')
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        ('A', '1', array['A', 'B', 'C', 'D', 'E']),
        ('B', '1', array['A', 'B', 'C', 'D', 'E']),
        ('C', '1', array['A', 'B', 'C', 'D', 'E']),
        ('D', '1', array['A', 'B', 'C', 'D', 'E']),
        ('E', '1', array['A', 'B', 'C', 'D', 'E'])
    ) as v (vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
