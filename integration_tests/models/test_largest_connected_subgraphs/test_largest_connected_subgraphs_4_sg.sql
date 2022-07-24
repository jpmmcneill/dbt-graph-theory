with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_4_sg_data')
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        ('A', '1', array['A', 'B', 'C', 'D']),
        ('B', '1', array['A', 'B', 'C', 'D']),
        ('C', '1', array['A', 'B', 'C', 'D']),
        ('D', '1', array['A', 'B', 'C', 'D']),
        ('E', '2', array['E', 'F']),
        ('F', '2', array['E', 'F']),
        ('G', '3', array['G']),
        ('H', '4', array['H', 'I']),
        ('I', '4', array['H', 'I'])
    ) as v (vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
