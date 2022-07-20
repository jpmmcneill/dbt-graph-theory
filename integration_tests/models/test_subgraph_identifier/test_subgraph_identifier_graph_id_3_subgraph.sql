with computed as (
    {{ dbt_graph_theory.subgraph_identifier(
        input=ref('test_subgraph_identifier_graph_id_3_subgraph_data'),
        graph_id='graph_id'
    )}}
),

subgraph_members as (
    select * from (
        values
            (1, 1, 'A', 'B', '1__1', array['A', 'B', 'C', 'D']),
            (1, 2, 'B', 'A', '1__1', array['A', 'B', 'C', 'D']),
            (1, 3, 'A', 'C', '1__1', array['A', 'B', 'C', 'D']),
            (1, 4, 'C', 'D', '1__1', array['A', 'B', 'C', 'D']),
            (1, 5, 'D', 'A', '1__1', array['A', 'B', 'C', 'D']),
            (1, 6, 'E', 'F', '1__2', array['E', 'F', 'G', 'H']),
            (1, 7, 'F', 'G', '1__2', array['E', 'F', 'G', 'H']),
            (1, 8, 'G', 'E', '1__2', array['E', 'F', 'G', 'H']),
            (1, 9, 'F', 'H', '1__2', array['E', 'F', 'G', 'H']),
            (1, 10, 'I', 'J', '1__3', array['I', 'J']),
            (2, 1, 'A', 'B', '2__1', array['A', 'B', 'C']),
            (2, 2, 'B', 'C', '2__1', array['A', 'B', 'C']),
            (2, 3, 'D', null, '2__2', array['D']),
            (2, 4, 'E', 'F', '2__3', array['E', 'F', 'G', 'H']),
            (2, 5, 'F', 'G', '2__3', array['E', 'F', 'G', 'H']),
            (2, 6, 'G', 'E', '2__3', array['E', 'F', 'G', 'H']),
            (2, 7, 'F', 'H', '2__3', array['E', 'F', 'G', 'H'])
    ) as t (graph_id, id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference('computed', 'subgraph_members', fields=["graph_id", "id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}
