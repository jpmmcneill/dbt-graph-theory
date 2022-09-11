{% test graph_is_connected(
    model,
    edge_id,
    vertex_1,
    vertex_2,
    graph_id=none
) %}

with connected_subgraphs as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=model,
        edge_id=edge_id,
        vertex_1=vertex_1,
        vertex_2=vertex_2,
        graph_id=graph_id
    ) }}
),

subgraphs_per_graph as (
    select
        {{ 'graph_id,' if graph_id }}
        count(distinct subgraph_id) as num_subgraphs
    from
        connected_subgraphs
    {{ 'group by graph_id' if graph_id }}
)

select * from subgraphs_per_graph
where num_subgraphs != 1

{% endtest %}
