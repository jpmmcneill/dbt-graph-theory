with computed as (
    {{ dbt_graph_theory.subgraph_identifier(
        input=ref('test_subgtaph_identifier_no_data_graph_id_data'),
        graph_id='graph_id'
    )}}
),

subgraph_members as (
    select * from (
        values
            (null::integer, null::integer, null::integer, null::integer, null::text, array[null])
    ) as t (graph_id, id, vertex_1, vertex_2, subgraph_id, subgraph_members)
    where false
)

select * from {{ cte_difference('computed', 'subgraph_members', fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}
