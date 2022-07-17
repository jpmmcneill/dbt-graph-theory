-- default input structure is:
-- id
-- vertex_1
-- vertex_2

{% macro subgraph_identifier(
    input,
    edge_id='id',
    vertex_1='vertex_1',
    vertex_2='vertex_2',
    graph_id=none
) %}
    {#
        This macro returns the same table, with two additional fields:

        Parameters:
        input: description
        edge_id: description
        vertex_1: description
        vertex_2: description
        graph_id (Optional, default = None): description
    #}
    
    with recursive rename_input as (
        select
            {{ graph_id if graph_id else '1'}} as graph_id,
            {{ edge_id }} as id,
            {{ vertex_1 }} as vertex_1,
            {{ vertex_2 }} as vertex_2
        from
            {{ input }}
    ),
    
    all_vertexs as (
        select
            graph_id,
            vertex_1 as vertex
        from rename_input
        where vertex_1 is not null
        union
        select
            graph_id,
            vertex_2 as vertex
        from rename_input
        where vertex_2 is not null
    ),

    {# enforce bi-directional edges #}
    all_edges as (
        select
            graph_id,
            vertex_1,
            vertex_2
        from
            rename_input
        where
            coalesce(vertex_1 != vertex_2, true) and
            (vertex_1 is not null or vertex_2 is not null)
        union
        select
            graph_id,
            vertex_2 as vertex_1,
            vertex_1 as vertex_2
        from
            rename_input
        where
            coalesce(vertex_1 != vertex_2, true) and
            (vertex_1 is not null or vertex_2 is not null)
    ),

    graph_walk as (
        select
            all_vertexs.graph_id,
            all_vertexs.vertex as orig_vertex,
            all_edges.vertex_1,
            all_edges.vertex_2,
            {{ dbt_graph_theory.array_construct(components=['all_edges.vertex_1', 'all_edges.vertex_2']) }} as path_array
        from 
            all_edges
        inner join all_vertexs on
            all_vertexs.vertex = all_edges.vertex_1
        union all
        select
            graph_walk.graph_id,
            graph_walk.orig_vertex,
            all_edges.vertex_1,
            all_edges.vertex_2,
            {{ dbt_graph_theory.array_append(array='graph_walk.path_array', new_value='all_edges.vertex_2') }} as path_array
        from
            all_edges
        inner join graph_walk on
            -- walk from the "end" vertex of the last edge to the "start" vertex of the next edge
            -- only walk there if the target vertex has not already been reached on the walk
            -- note: while this does not guarantee full coverage on each path, it means that every reachable vertex from every original vertex has a row.
            graph_walk.vertex_2 = all_edges.vertex_1 and
            not({{ dbt_graph_theory.array_contains(array='graph_walk.path_array', value='all_edges.vertex_2') }}) and
            graph_walk.graph_id = all_edges.graph_id
    ),

    all_paths as (
        select
            graph_id,
            orig_vertex,
            vertex_1 as end_vertex
        from
            graph_walk
        union
        select
            graph_id,
            orig_vertex,
            vertex_2 as end_vertex
        from
            graph_walk
    ),

    node_subgraphs as (
        select
            graph_id,
            orig_vertex as vertex,
            {{ dbt_graph_theory.array_agg(field='end_vertex', distinct=true, order_field='end_vertex', order='asc') }} as subgraph_members
        from all_paths
        group by
            graph_id,
            orig_vertex
    ),

    generate_subgraph_id as (
        select
            graph_id,
            vertex,
            subgraph_members,
            dense_rank() over (partition by graph_id order by subgraph_members) as subgraph_id
        from node_subgraphs
    ),

    join_detail as (
        select
            _input.*,
            concat(
                {{ graph_id if graph_id else "''"}}::text,
                {{ "'__,'" if graph_id }}
                subgraphs.subgraph_id
            ) as subgraph_id,
            subgraphs.subgraph_members
        from {{ input }} as _input
        left join generate_subgraph_id as subgraphs on
            coalesce(_input.{{ vertex_1 }}, _input.{{ vertex_2 }}) = subgraphs.vertex
    )

    select * from join_detail
{% endmacro %}
