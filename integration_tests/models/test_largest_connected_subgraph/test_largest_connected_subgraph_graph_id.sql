with computed as (
    {{ dbt_graph_theory.largest_connected_subgraph(
        input=ref('test_largest_connected_subgraph_graph_id_data'),
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
        (1, 'E', '1__2', array['E']),
        (2, 'A', '2__1', array['A', 'B', 'C', 'D']),
        (2, 'B', '2__1', array['A', 'B', 'C', 'D']),
        (2, 'C', '2__1', array['A', 'B', 'C', 'D']),
        (2, 'D', '2__1', array['A', 'B', 'C', 'D'])
    ) as v (graph_id, vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["graph_id", "vertex", "subgraph_id", "subgraph_members"]
) }}
