with recast as (
    select
        id,
        vertex_1,
        vertex_2,
        order_int
    from {{ ref('test_connect_ordered_graph_2_sg_numeric_tangled_data') }}
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
        ('2', 'B', 'C', 5),
        ('3', 'C', 'D', 2),
        ('4', 'E', 'F', 6),
        ('5', 'F', 'G', 3),
        ('6', 'G', 'H', 5),
        -- edges are inserted from the max moving backwards. here, 3 is the min of the "max" subgraph
        -- so an edge is inserted from the edge with ordering 3 to the edge with ordering less than that, being the max in the lower subgraph
        ('inserted_edge_1', 'D', 'F', 2.5)
    ) as v (id, vertex_1, vertex_2, order_int)
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["id", "vertex_1", "vertex_2", "order_int"]
) }}
