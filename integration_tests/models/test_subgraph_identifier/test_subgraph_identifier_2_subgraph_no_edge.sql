with computed as (
    {{ dbt_graph_theory.subgraph_identifier(
        input=ref('test_subgraph_identifier_2_subgraphs_no_edge_data')
    )}}
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
    select * from (
        values
            (1, 'A', null, '1', array['A']),
            (2, 'B', null, '2', array['B'])
    ) as t (id, vertex_1, vertex_2, subgraph_id, subgraph_members)
)

select * from {{ cte_difference('recast_computed', 'subgraph_members', fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}
