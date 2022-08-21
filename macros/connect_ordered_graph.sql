{% macro connect_ordered_graph(
    input,
    edge_id='id',
    vertex_1='vertex_1',
    vertex_2='vertex_2',
    ordering={'edge_order': 'numeric'},
    graph_id=none
) %}
    {#
        This macro takes an ordered graph in the given structure, and connects any unconnected subgraphs.
        Additional fields are dropped - if these are required, they should be joined back in.
        
        Required [minimal] table structure:
        graph_id (Optional, text):
            An identifier at the graph level (ie. if the table in question represents multiple graphs).
            When this is not defined, it is assumed that the table represents the one graph.
        edge_id (text):
            An identifier of the edge (from vertex_1 to vertex_2). This field should be unique at the graph level.
        vertex_1 (text):
            The alias for the first (origin, for directed graphs) vertex of the given edge_id.
            Nulls are allowed, and correspond to the given vertex_2 not being connected to any other vertices.
        vertex_2 (text):
            The alias for the second (destination, for directed graphs) vertex of the given edge_id.
            Nulls are allowed, and correspond to the given vertex_1 not being connected to any other vertices.
        ordering (timestamp, date or numeric):
            The field corresponding to the order of the edges of the given graph. This is used to connect sensible nodes to each other
            (ie. in order from one subgraph to the other).

        It returns a query giving a vertex / graph level table with the following fields:
        graph_id (text):
            Identifies the graph based on the input table. If graph_id was not present in the input table, this field is always '1'.
        vertex (text):
            Identifies the vertex that the given subgraph and subgraph_members corresponds to. This (as well as graph_id) defines the level of the table.
        subgraph_id (text):
            An identifier of the (connected) subgraph for the given vertices for the given edge.
            This is unique at the graph level.  
        subgraph_members (array[Any]):
            An array of the vertices that constitute the given subgraph. The data type of the array is that of the vertex_1 and vertex_2 fields. 

        Parameters:
        input (text or a ref / source): The input model or CTE that follows the structure above.
        edge_id (text): The field corresponding to the edge_id field described above.
        vertex_1 (text): The field corresponding to the vertex_1 field described above.
        vertex_2 (text): The field corresponding to the vertex_2 field described above.
        ordering (dict[text, text]):
            A dict with key being the field corresponding to the ordering as descripted above,
            and the value being the data type of the given field.
            For example, { 'event_time' : 'timstamp' } corresponds to a field named event_time of type timestamp.
            The data type must be one of: 'timestamp', 'date', 'numeric'.
        graph_id (text, Optional, default = None): The field corresponding to the graph_id field described above.
    #}

{% set supported_ordering_types = ['numeric', 'timestamp', 'date'] %}

{% set ordering_field = ordering.keys()|list|first %}
{% set ordering_type = ordering.values()|list|first %}

{{ exceptions.raise_compiler_error(
    'Please input a supported ordering type - must be one of: '~ supported_ordering_types
) if ordering_type not in supported_ordering_types }}

with subgraphs as (
    {{ dbt_graph_theory.largest_connected_subgraphs(
        input=input,
        edge_id=edge_id,
        vertex_1=vertex_1,
        vertex_2=vertex_2,
        graph_id=graph_id
    ) }}
),

enforce_graph_types as (
    select
        {{ graph_id if graph_id else '1::text'}}::text as graph_id,
        {{ edge_id }}::text as edge_id,
        {{ vertex_1 }}::text as vertex_1,
        {{ vertex_2 }}::text as vertex_2,
        {% if ordering_type == 'timestamp' %}
        {{ dbt_graph_theory.cast_timestamp(ordering_field) }} as ordering
        {% else %}
        {{ ordering_field }}::{{ordering_type}} as ordering
        {% endif %}
    from
        {{ input }}
),

from_vertices as (
    select
        _input.graph_id,
        _input.vertex_1 as vertex,
        _input.ordering,
        subgraphs.subgraph_id
    from enforce_graph_types as _input
    inner join subgraphs on
        _input.graph_id = subgraphs.graph_id and
        _input.vertex_1 = subgraphs.vertex
),

to_vertices as (
    select
        _input.graph_id,
        _input.vertex_2 as vertex,
        _input.ordering,
        subgraphs.subgraph_id
    from enforce_graph_types as _input
    inner join subgraphs on
        _input.graph_id = subgraphs.graph_id and
        _input.vertex_2 = subgraphs.vertex
),

vertex_ordering as (
    select
        graph_id,
        vertex,
        ordering
    from from_vertices
    union
    select
        graph_id,
        vertex,
        ordering
    from to_vertices
),

vertex_min_max_ordering as (
    select
        graph_id,
        vertex,
        max(ordering) as max_ordering,
        min(ordering) as min_ordering
    from vertex_ordering
    group by 
        graph_id,
        vertex
),

subgraph_max_min_ordering as (
    select
        subgraphs.graph_id,
        subgraphs.subgraph_id,
        subgraphs.subgraph_members,
        min(orderings.min_ordering) as min_ordering,
        max(orderings.max_ordering) as max_ordering
    from
        subgraphs
    inner join
        vertex_min_max_ordering as orderings on
            subgraphs.graph_id = orderings.graph_id and
            subgraphs.vertex = orderings.vertex
    group by
        subgraphs.graph_id,
        subgraphs.subgraph_id,
        subgraphs.subgraph_members
),

subgraph_lead_lags as (
    select
        graph_id,
        subgraph_id,
        min_ordering,
        max_ordering,
        lag(subgraph_id) over (partition by graph_id order by min_ordering) as lag_subgraph_id,
        lag(max_ordering) over (partition by graph_id order by min_ordering) as lag_max_ordering
    from
        subgraph_max_min_ordering
),

new_edges_join as (
    select
        _required_edges.graph_id,
        to_vertices.vertex as vertex_1,
        to_vertices.ordering as old_ordering,
        from_vertices.vertex as vertex_2,
        from_vertices.ordering as new_ordering,
        -- the join condition ensure that we need to be able to dedupe a > condition, we use this field to do that - ie. we pick the most recent
        -- "to_vertices" row that has joined (ie. is less than the required max ordering (min_ordering in the next subgraph))
        row_number() over (partition by to_vertices.graph_id, to_vertices.subgraph_id order by to_vertices.ordering desc) = 1 as is_max_to_vertex_joined
    from
        subgraph_lead_lags as _required_edges
    inner join
        from_vertices on
            -- this is the vertex in the subgraph that has the min ordering
            _required_edges.graph_id = from_vertices.graph_id and
            _required_edges.subgraph_id = from_vertices.subgraph_id and
            _required_edges.min_ordering = from_vertices.ordering
    inner join
        to_vertices on
            -- these are the vertices in the previous subgraph that have an ordering less than the min of the subgraph
            _required_edges.graph_id = to_vertices.graph_id and
            _required_edges.lag_subgraph_id = to_vertices.subgraph_id and
            _required_edges.min_ordering > to_vertices.ordering
    -- filter out the "first" subgraph id - the remainder is exactly the number of new edges required.
    where _required_edges.lag_max_ordering is not null
),

include_new_edges as (
    select
        {{ 'graph_id as ' ~ graph_id ~ ',' if graph_id }}
        edge_id as {{ edge_id }},
        ordering as {{ ordering_field }},
        vertex_1 as {{ vertex_1 }}, 
        vertex_2 as {{ vertex_2 }}
    from enforce_graph_types
    union all
    select
        {{ 'graph_id as ' ~ graph_id ~ ',' if graph_id }}
        concat(
            {{ "graph_id::text, '_'," if graph_id }} 
            'inserted_edge_',
            row_number() over (order by graph_id, vertex_1)::text
        ) as {{ edge_id }},
        {% if ordering_type == 'timestamp' %}
        case
            when
                new_ordering = old_ordering or
                old_ordering = {{ dbt_utils.dateadd('second', '-1', 'new_ordering') }}
                then new_ordering
            else {{ dbt_utils.dateadd('second', '-1', 'new_ordering') }}
        end
        {% elif ordering_type == 'date' %}
        case
            when
                new_ordering = old_ordering or
                old_ordering = {{ dbt_utils.dateadd('day', '-1', 'new_ordering') }}
                then new_ordering
            else {{ dbt_utils.dateadd('day', '-1', 'new_ordering') }}
        end
        {% elif ordering_type == 'numeric' %}
        old_ordering + (new_ordering - old_ordering) / 2
        {% endif %} as {{ ordering_field }},
        vertex_1 as {{ vertex_1 }},
        vertex_2 as {{ vertex_2 }}
    from new_edges_join
    -- drop any incorrect rows joined previously by the > join condition
    where is_max_to_vertex_joined
)

select * from include_new_edges
{% endmacro %}
