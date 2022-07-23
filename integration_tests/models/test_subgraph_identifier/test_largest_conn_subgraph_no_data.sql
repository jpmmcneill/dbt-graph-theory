with computed as (
    {{ dbt_graph_theory.largest_connected_largest_conn_subgraph(
        input=ref('test_largest_conn_subgraph_no_data_data')
    ) }}
),

subgraph_members as (
    select * from (
        values
        (null::integer, null::integer, null::integer, null::text, array[null])
    )
    where false
)

select * from {{ cte_difference('computed', 'subgraph_members', fields=["id", "vertex_1", "vertex_2", "subgraph_id", "subgraph_members"]) }}
