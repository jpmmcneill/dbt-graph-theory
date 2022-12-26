with computed as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=ref('test_largest_connected_subgraphs_nd_data')
    ) }}
),

required as (
    select v.* from
    {{ dbt_graph_theory.sql_values(
        data=[
            ['null', 'null', dbt_graph_theory.array_construct(["1"])]
        ],
        metadata={
            "names": ["vertex", "subgraph_id", "subgraph_members"],
            "types": ["text", "text", "array<text>"]
        }
    ) }}
    where false
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["vertex", "subgraph_id", "subgraph_members"]
) }}
