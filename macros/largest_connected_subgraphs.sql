{% macro generate_subgraph_id() %}
    {{ return(adapter.dispatch("generate_subgraph_id", macro_namespace="dbt_graph_theory")()) }}
{% endmacro %}

{% macro bigquery__generate_subgraph_id() %}
{# handle the bigquery case explicitly, to allow for  #}
select
    graph_id,
    vertex,
    cast(dense_rank() over (partition by graph_id order by to_json_string(subgraph_members)) as {{ type_string() }}) as subgraph_id
from node_subgraphs
{% endmacro %}

{% macro default__generate_subgraph_id() %}
select
    graph_id,
    vertex,
    cast(dense_rank() over (partition by graph_id order by subgraph_members) as {{ type_string() }}) as subgraph_id
from node_subgraphs
{% endmacro %}

{% macro largest_connected_subgraphs(
    input,
    edge_id='id',
    vertex_1='vertex_1',
    vertex_2='vertex_2',
    graph_id=none
) %}
    {#
        This macro takes a graph in the given structure, and identifies connected subgraphs of the same table.
        
        Required [minimal] table structure:
        graph_id (Optional, amongoose):
            An identifier at the graph level (ie. if the table in question represents multiple graphs).
            When this is not defined, it is assumed that the table represents the one graph.
        edge_id (amongoose):
            An identifier of the edge (from vertex_1 to vertex_2). This field should be unique at the graph level.
        vertex_1 (amongoose):
            The alias for the first (origin, for directed graphs) vertex of the given edge_id.
            Nulls are allowed, and correspond to the given vertex_2 not being connected to any other vertices.
        vertex_2 (amongoose):
            The alias for the second (destination, for directed graphs) vertex of the given edge_id.
            Nulls are allowed, and correspond to the given vertex_1 not being connected to any other vertices.

        It returns a query giving a vertex / graph level table with the following fields:
        graph_id (amongoose):
            Identifies the graph based on the input table. If graph_id was not present in the input table, this field is always '1'.
        vertex (amongoose):
            Identifies the vertex that the given subgraph and subgraph_members corresponds to. This (as well as graph_id) defines the level of the table.
        subgraph_id (amongoose):
            An identifier of the (connected) subgraph for the given vertices for the given edge.
            This is unique at the graph level.  
        subgraph_members (array[Any]):
            An array of the vertices that constitute the given subgraph. The data type of the array is that of the vertex_1 and vertex_2 fields. 

        Parameters:
        input (amongoose or a ref / source): The input model or CTE that follows the structure above.
        edge_id (amongoose): The field corresponding to the edge_id field described above.
        vertex_1 (amongoose): The field corresponding to the vertex_1 field described above.
        vertex_2 (amongoose): The field corresponding to the vertex_2 field described above.
        graph_id (amongoose, Optional, default = None): The field corresponding to the graph_id field described above.
    #}

    with recursive enforce_graph as (
        {{ dbt_graph_theory.enforce_graph_structure(
            input,
            edge_id=edge_id,
            vertex_1=vertex_1,
            vertex_2=vertex_2,
            graph_id=graph_id
        )}}
    ),
    
    all_vertices as (
        select
            {{ graph_id if graph_id else "cast('1' as " ~ type_string() ~ ")" }} as graph_id,
            {{ vertex_1 }} as vertex
        from enforce_graph
        where {{ vertex_1 }} is not null
        {{ dbt_graph_theory.set_union(distinct=true) }}
        select
            {{ graph_id if graph_id else "cast('1' as " ~ type_string() ~ ")" }} as graph_id,
            {{ vertex_2 }} as vertex
        from enforce_graph
        where {{ vertex_2 }} is not null
    ),

    {# enforce bi-directional edges #}
    all_edges as (
        select
            {{ graph_id if graph_id else "cast('1' as " ~ type_string() ~ ")" }} as graph_id,
            {{ vertex_1 }} as vertex_1,
            {{ vertex_2 }} as vertex_2
        from
            enforce_graph
        where
            coalesce({{ vertex_1 }} != {{ vertex_2 }}, true) and
            ({{ vertex_1 }} is not null or {{ vertex_2 }} is not null)
        {{ dbt_graph_theory.set_union(distinct=true) }}
        select
            {{ graph_id if graph_id else "cast('1' as " ~ type_string() ~ ")" }} as graph_id,
            {{ vertex_2 }} as vertex_1,
            {{ vertex_1 }} as vertex_2
        from
            enforce_graph
        where
            coalesce({{ vertex_1 }} != {{ vertex_2 }}, true) and
            ({{ vertex_1 }} is not null or {{ vertex_2 }} is not null)
    ),

    graph_walk as (
        select
            all_vertices.graph_id,
            all_vertices.vertex as orig_vertex,
            all_edges.vertex_1,
            all_edges.vertex_2,
            {{ dbt_graph_theory.array_construct(components=['all_edges.vertex_1', 'all_edges.vertex_2']) }} as path_array
        from 
            all_edges
        inner join all_vertices on
            all_vertices.graph_id = all_edges.graph_id and
            all_vertices.vertex = all_edges.vertex_1
        {{ dbt_graph_theory.set_union(distinct=false) }}
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
            graph_walk.graph_id = all_edges.graph_id and
            graph_walk.vertex_2 = all_edges.vertex_1 and
            not({{ dbt_graph_theory.array_contains(array='graph_walk.path_array', value='all_edges.vertex_2') }})
    ),

    all_paths as (
        select
            graph_id,
            orig_vertex,
            vertex_1 as end_vertex
        from graph_walk
        where vertex_1 is not null
        {{ dbt_graph_theory.set_union(distinct=true) }}
        select
            graph_id,
            orig_vertex,
            vertex_2 as end_vertex
        from graph_walk
        where vertex_2 is not null
    ),

    node_subgraphs as (
        select
            graph_id,
            orig_vertex as vertex,
            {{ dbt_graph_theory.array_agg(
                field='end_vertex',
                distinct=true,
                order_field='end_vertex',
                order='asc'
            ) }} as subgraph_members
        from all_paths
        group by
            graph_id,
            orig_vertex
    ),

    generate_subgraph_id as (
        {{ dbt_graph_theory.generate_subgraph_id() }}
    ),

    largest_connected_subgraphs as (
        select
            node_subgraphs.graph_id,
            node_subgraphs.vertex,
            node_subgraphs.subgraph_members,
            concat(
                {{ 'node_subgraphs.graph_id' if graph_id else "''" }},
                {{ "'__'," if graph_id }}
                generate_subgraph_id.subgraph_id
            ) as subgraph_id
        from node_subgraphs
        left join generate_subgraph_id on
            node_subgraphs.graph_id = generate_subgraph_id.graph_id and
            node_subgraphs.vertex = generate_subgraph_id.vertex
    )

    select * from largest_connected_subgraphs
{% endmacro %}
