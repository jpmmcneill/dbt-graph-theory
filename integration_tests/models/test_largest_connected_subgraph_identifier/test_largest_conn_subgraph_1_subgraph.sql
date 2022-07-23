with computed as (
    {{ dbt_graph_theory.largest_connected_largest_conn_subgraph(
        input=ref('test_largest_conn_subgraph_1_subgraph_data')
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        (1, 'A', 'B', '1', array['A', 'B', 'C', 'D', 'E']),
        (2, 'B', 'C', '1', array['A', 'B', 'C', 'D', 'E']),
        (3, 'C', 'D', '1', array['A', 'B', 'C', 'D', 'E']),
        (4, 'B', 'D', '1', array['A', 'B', 'C', 'D', 'E']),
        (5, 'A', 'C', '1', array['A', 'B', 'C', 'D', 'E']),
        (6, 'B', 'E', '1', array['A', 'B', 'C', 'D', 'E']),
        (7, 'E', 'D', '1', array['A', 'B', 'C', 'D', 'E']),
        (8, 'A', null, '1', array['A', 'B', 'C', 'D', 'E']),
        (9, 'E', null, '1', array['A', 'B', 'C', 'D', 'E'])
    ) as v (id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]
) }}
