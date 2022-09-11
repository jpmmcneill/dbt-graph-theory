with recast as (
    select
        id,
        vertex_1,
        vertex_2,
        order_int
    from {{ ref('test_connect_ordered_graph_2_sg_numeric_data') }}
),

computed as (
    {{ dbt_graph_theory.connect_ordered_graph(
        input='recast',
        edge_id='id',
        vertex_1='vertex_1',
        vertex_2='vertex_2',
        ordering={"order_int": "numeric"}
    ) }}
),

required as (
    select v.* from (
        values
        ('1', 'A', 'B', 1),
        ('2', 'B', 'C', 2),
        ('3', 'C', 'D', 3),
        ('4', 'E', 'F', 4),
        ('5', 'F', 'G', 5),
        ('6', 'G', 'H', 6),
        ('inserted_edge_1', 'D', 'E', 3.5)
    ) as v (id, vertex_1, vertex_2, order_int)
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["id", "vertex_1", "vertex_2", "order_int"]
) }}
