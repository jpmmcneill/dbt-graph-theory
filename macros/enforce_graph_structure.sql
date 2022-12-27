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
        input (string or a ref / source): The input model or CTE that follows the structure above.
        edge_id (string): The edge_id field of the given input.
        vertex_1 (string): The vertex_1 field of the given input.
        vertex_2 (string): The vertex_2 field of the given input.
        graph_id (string, Optional, default = None): The (optional) graph_di field of the given input.
    #}

select
    cast({{ edge_id }} as {{ type_string() }}) as {{ edge_id }},
    {{ 'cast(' ~ graph_id ~ ' as ' ~ type_string() ~ ') as ' ~ graph_id ~ ',' if graph_id }}
    cast({{ vertex_1 }} as {{ type_string() }}) as {{ vertex_1 }},
    cast({{ vertex_2 }} as {{ type_string() }}) as {{ vertex_2 }}
from
    {{ input }}
{% endmacro %}
