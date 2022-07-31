with recast as (
    select
        id,
        vertex_1,
        vertex_2,
        order_date::date as order_date
    from {{ ref('test_connect_ordered_graph_3_sg_date_data') }}
),

computed as (
    {{ dbt_graph_theory.connect_ordered_graph(
        input='recast',
        edge_id='id',
        vertex_1='vertex_1',
        vertex_2='vertex_2',
        ordering={"order_date": "date"}
    ) }}
),

subgraph_members as (
    select v.* from (
        values
        ('1', 'A', 'B', '2022-01-01'::date),
        ('2', 'B', 'C', '2022-01-03'::date),
        ('3', 'C', 'D', '2022-01-05'::date),
        ('4', 'E', 'F', '2022-01-08'::date),
        ('5', 'F', 'G', '2022-01-16'::date),
        ('6', 'H', 'I', '2022-01-27'::date),
        ('inserted_edge_1', 'D', 'E', '2022-01-07'::date),
        ('inserted_edge_2', 'G', 'H', '2022-01-26'::date)
    ) as v (id, vertex_1, vertex_2, order_date)
)

select * from {{ cte_difference(
    'computed',
    'subgraph_members',
    fields=["id", "vertex_1", "vertex_2", "order_date"]
) }}
