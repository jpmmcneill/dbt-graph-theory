with computed as (
    {{ dbt_graph_theory.subgraph_identifier(
        input=ref('test_subgraph_identifier_3_subgraph_no_edge_data')
    )}}
),

subgraph_members as (
    select * from (
        values
            (1, 'A', null, '1', array['A']),
            (2, 'B', null, '2', array['B']),
            (3, null, 'C', '3', array['C'])
    ) as t (id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference('computed', 'subgraph_members', fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}
