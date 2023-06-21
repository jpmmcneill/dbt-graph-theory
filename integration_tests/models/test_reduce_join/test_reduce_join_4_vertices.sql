with recursive computed as (
    {{ dbt_graph_theory.reduce_join(input=ref("test_join_reduce_data_4_vertices")) }}
),

required as (
    select v.* from (
        values
        ('A', 'A_'),
        ('B', 'C_'),
        ('C', 'B_'),
        ('D', 'D_'),
    ) as v (vertex_1, vertex_2)
)

select * from {{ cte_difference(
    'computed',
    'required',
    fields=["vertex_1", "vertex_2"]
) }}
