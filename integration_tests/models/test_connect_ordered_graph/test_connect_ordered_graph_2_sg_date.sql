with recast as (
    select
        id,
        vertex_1,
        vertex_2,
        cast(order_date as date) as order_date
    from {{ ref('test_connect_ordered_graph_2_sg_date_data') }}
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

required as (
    select v.* from (
        values
        ('1', 'A', 'B', cast('2022-01-01' as date)),
        ('2', 'B', 'C', cast('2022-01-03' as date)),
        ('3', 'C', 'D', cast('2022-01-05' as date)),
        ('4', 'E', 'F', cast('2022-01-08' as date)),
        ('5', 'F', 'G', cast('2022-01-16' as date)),
        ('inserted_edge_1', 'D', 'E', cast('2022-01-07' as date))
    ) as v (id, vertex_1, vertex_2, order_date)
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["id", "vertex_1", "vertex_2", "order_date"]
) }}
