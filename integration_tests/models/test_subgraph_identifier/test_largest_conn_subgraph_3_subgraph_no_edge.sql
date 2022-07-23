with computed as (
    {{ dbt_graph_theory.largest_connected_largest_conn_subgraph(
        input=ref('test_largest_conn_subgraph_3_subgraph_no_edge_data')
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        (1, 'A', null, '1', array['A']),
        (2, 'B', null, '2', array['B']),
        (3, null, 'C', '3', array['C'])
    ) as v
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]
) }}
