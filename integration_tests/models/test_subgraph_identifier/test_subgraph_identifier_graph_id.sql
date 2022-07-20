with computed as (
    {{ dbt_graph_theory.subgraph_identifier(
        input=ref('test_subgraph_identifier_graph_id_data'),
        graph_id='graph_id'
    )}}
),

subgraph_members as (
    select * from (
        values
            (1, 1, 'A', 'B', '1__1', array['A', 'B', 'C', 'D']),
            (1, 2, 'B', 'C', '1__1', array['A', 'B', 'C', 'D']),
            (1, 3, 'C', 'D', '1__1', array['A', 'B', 'C', 'D']),
            (1, 4, 'E', null, '1__2', array['E']),
            (2, 1, 'A', 'B', '2__1', array['A', 'B', 'C', 'D']),
            (2, 2, 'B', 'C', '2__1', array['A', 'B', 'C', 'D']),
            (2, 3, 'C', 'D', '2__1', array['A', 'B', 'C', 'D'])
    ) as t (graph_id, id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference('computed', 'subgraph_members', fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}