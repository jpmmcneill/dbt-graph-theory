with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_gid_3_sg_data'),
        graph_id='graph_id'
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        (1, 'A', '1__1', array['A', 'B', 'C', 'D']),
        (1, 'B', '1__1', array['A', 'B', 'C', 'D']),
        (1, 'C', '1__1', array['A', 'B', 'C', 'D']),
        (1, 'D', '1__1', array['A', 'B', 'C', 'D']),
        (1, 'E', '1__2', array['E', 'F', 'G', 'H']),
        (1, 'F', '1__2', array['E', 'F', 'G', 'H']),
        (1, 'G', '1__2', array['E', 'F', 'G', 'H']),
        (1, 'H', '1__2', array['E', 'F', 'G', 'H']),
        (1, 'I', '1__3', array['I', 'J']),
        (1, 'J', '1__3', array['I', 'J']),
        (2, 'A', '2__1', array['A', 'B', 'C']),
        (2, 'B', '2__1', array['A', 'B', 'C']),
        (2, 'C', '2__1', array['A', 'B', 'C']),
        (2, 'D', '2__2', array['D']),
        (2, 'E', '2__3', array['E', 'F', 'G', 'H']),
        (2, 'F', '2__3', array['E', 'F', 'G', 'H']),
        (2, 'G', '2__3', array['E', 'F', 'G', 'H']),
        (2, 'H', '2__3', array['E', 'F', 'G', 'H'])
    ) as v (graph_id, vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["graph_id", "vertex", "subgraph_id", "subgraph_members"]
) }}
