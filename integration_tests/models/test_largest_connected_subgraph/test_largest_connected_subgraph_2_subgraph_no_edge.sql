with computed as (
    {{ dbt_graph_theory.largest_connected_largest_connected_subgraph(
        input=ref('test_largest_connected_subgraph_2_subgraph_no_edge_data')
    ) }}
),

-- recast because vertex_2 is all null in seed data, interpreted as int dtype
recast_computed as (
    select
        vertex::text as vertex,
        subgraph_id,
        subgraph_members
    from
        computed
),

subgraph_members as (
    select v.* from (
        values
        ('A', '1', array['A']),
        ('B', '2', array['B'])
    ) as v (vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'recast_computed',
    'subgraph_members',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
