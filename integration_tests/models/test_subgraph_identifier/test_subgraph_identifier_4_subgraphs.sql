with computed as (
    {{ dbt_graph_theory.subgraph_identifier(
        input=ref('test_subgraph_identifier_4_subgraphs_data')
    )}}
),

subgraph_members as (
    select * from (
        values
            (1, 'A', 'B', '1', array['A', 'B', 'C', 'D']),
            (2, 'B', 'C', '1', array['A', 'B', 'C', 'D']),
            (3, 'C', 'D', '1', array['A', 'B', 'C', 'D']),
            (4, 'E', null, '2', array['E', 'F']),
            (5, 'E', 'F', '2', array['E', 'F']),
            (6, 'G', null, '3', array['G']),
            (7, 'H', 'I', '4', array['H', 'I'])
    ) as t (id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference('computed', 'subgraph_members', fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}
