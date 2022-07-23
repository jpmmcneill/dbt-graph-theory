with computed as (
    {{ dbt_graph_theory.largest_connected_largest_conn_subgraph(
        input=ref('test_largest_conn_subgraph_2_subgraph_no_edge_data')
    ) }}
),

-- recast because vertex_2 is all null in seed data, interpreted as int dtype
recast_computed as (
    select
        id,
        vertex_1,
        vertex_2::text as vertex_2,
        subgraph_id,
        subgraph_members
    from
        computed
),

subgraph_members as (
    select v.* from (
        values
        (1, 'A', null, '1', array['A']),
        (2, 'B', null, '2', array['B'])
    ) as v (id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'recast_computed',
    'subgraph_members',
    fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]
) }}
