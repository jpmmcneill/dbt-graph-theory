with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_2_sg_ne_data')
    ) }}
),

-- recast because vertex_2 is all null in seed data, interpreted as int dtype
recast_computed as (
    select
        cast(vertex as text) as vertex,
        subgraph_id,
        subgraph_members
    from
        computed
),

required as (
    select v.* from (
        values
        ('A', '1', array['A']),
        ('B', '2', array['B'])
    ) as v (vertex, subgraph_id, subgraph_members)
)

select * from {{ cte_difference(
    'recast_computed',
    'required',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
