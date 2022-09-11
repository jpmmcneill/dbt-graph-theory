with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_3_sg_ne_data')
    ) }}
),

required as (
    select v.* from (
        values
        ('A', '1', array['A']),
        ('B', '2', array['B']),
        ('C', '3', array['C'])
    ) as v (vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
