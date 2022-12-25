{% macro enforce_graph_structure(
    input,
    edge_id='id',
    vertex_1='vertex_1',
    vertex_2='vertex_2',
    graph_id=none
) %}
    {#
        This macro takes a table and enforces that it follows the graph table structure.

        Parameters:
        input (text or a ref / source): The input model or CTE that follows the structure above.
        edge_id (text): The edge_id field of the given input.
        vertex_1 (text): The vertex_1 field of the given input.
        vertex_2 (text): The vertex_2 field of the given input.
        graph_id (text, Optional, default = None): The (optional) graph_di field of the given input.
    #}

select
    cast({{ edge_id }} as text) as {{ edge_id }},
    {{ 'cast(' ~ graph_id ~ ' as text) as ' ~ graph_id ~ ',' if graph_id }}
    cast({{ vertex_1 }} as text) as {{ vertex_1 }},
    cast({{ vertex_2 }} as text) as {{ vertex_2 }}
from
    {{ input }}
{% endmacro %}
