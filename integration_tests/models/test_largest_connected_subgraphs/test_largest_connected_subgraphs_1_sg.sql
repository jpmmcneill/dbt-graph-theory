with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_1_sg_data')
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
