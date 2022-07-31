{% macro connect_ordered_graph(
    input,
    edge_id='id',
    vertex_1='vertex_1',
    vertex_2='vertex_2',
    ordering={'edge_order': 'numeric'},
    graph_id=none
) %}

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
        {{ ordering_field }}::{{ordering_type}} as ordering
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
        concat('inserted_edge_', row_number() over (order by graph_id, vertex_1)::text) as {{ edge_id }},
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
