with recast as (
    select
        id,
        vertex_1,
        vertex_2,
        order_time::timestamp as order_time
    from {{ ref('test_connect_ordered_graph_4_sg_timestamp_data') }}
),

computed as (
    {{ dbt_graph_theory.connect_ordered_graph(
        input='recast',
        edge_id='id',
        vertex_1='vertex_1',
        vertex_2='vertex_2',
        ordering={"order_time": "timestamp"}
    ) }}
),

required as (
    select v.* from (
        values
        ('1', 'A', 'B', {{ dbt_graph_theory.cast_timestamp("'2022-01-01 10:26:45'") }}),
        ('2', 'B', 'C', {{ dbt_graph_theory.cast_timestamp("'2022-01-03 15:47:54'") }}),
        ('3', 'C', 'D', {{ dbt_graph_theory.cast_timestamp("'2022-01-05 23:16:16'") }}),
        ('4', 'E', 'F', {{ dbt_graph_theory.cast_timestamp("'2022-01-08 16:06:26'") }}),
        ('5', 'F', 'G', {{ dbt_graph_theory.cast_timestamp("'2022-01-16 04:12:34'") }}),
        ('6', 'H', 'I', {{ dbt_graph_theory.cast_timestamp("'2022-01-27 18:27:15'") }}),
        ('7', 'K', 'L', {{ dbt_graph_theory.cast_timestamp("'2022-01-29 15:23:46'") }}),
        ('8', 'L', 'M', {{ dbt_graph_theory.cast_timestamp("'2022-01-27 19:02:05'") }}),
        ('inserted_edge_1', 'D', 'E', {{ dbt_graph_theory.cast_timestamp("'2022-01-08 16:06:25'") }}),
        ('inserted_edge_2', 'G', 'H', {{ dbt_graph_theory.cast_timestamp("'2022-01-27 18:27:14'") }}),
        -- note that in this example, I and L are connected as these are the closest orderings.
        -- ie satisfying max(subgraph_1) < min(subgraph_2)
        ('inserted_edge_3', 'I', 'L', {{ dbt_graph_theory.cast_timestamp("'2022-01-27 19:02:04'") }})
    ) as v (id, vertex_1, vertex_2, order_time)
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["id", "vertex_1", "vertex_2", "order_time"]
) }}
