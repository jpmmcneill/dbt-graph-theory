{% macro enforce_graph_structure(
    input,
    edge_id='id',
    vertex_1='vertex_1',
    vertex_2='vertex_2',
    graph_id=none
) %}
select
    {{ edge_id }}::text as {{ edge_id }},
    {{ graph_id ~ '::text as ' ~ graph_id ~ ',' if graph_id }}
    {{ vertex_1 }}::text as {{ vertex_1 }},
    {{ vertex_2 }}::text as {{ vertex_2 }}
from
    {{ input }}
{% endmacro %}
