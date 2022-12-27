{% macro sql_values(data=[],metadata={"names": [], "types": []}, table_alias = "v") %}
{#
    sql_values is a list of ordered lists with the relevant sql_values.
    metadata is a dict with names and types as the two keys. Ordering is same as sql_values
#}
    {{ return(adapter.dispatch("sql_values", macro_namespace="dbt_graph_theory")(data, metadata, table_alias)) }}
{% endmacro %}

{% macro bigquery__sql_values(data, metadata, table_alias) %}

    {% set has_types = metadata.get("types", [])|length > 0 %}
    {% set has_names = metadata.get("names", [])|length > 0 %}
    (
    select * from unnest(
        [
        struct
        {% for row in data -%}
            
            {% if has_types %}
            {% set outer_loop = loop %}
            (
            {% for col in row -%}
            {% if has_names and outer_loop.first %}
                cast( {{ col }} as {{ metadata["types"][loop.index0] }}) as {{ metadata["names"][loop.index0] }} {{',' if not loop.last}}
            {% else %}
                cast( {{ col }} as {{ metadata["types"][loop.index0] }}) {{',' if not loop.last}}
            {% endif %}
            {%- endfor %}
            )

            {% else %}
            
            {% if has_types and outer_loop.first %}
                {% for col in row %}
                cast( {{ col }} as {{ metadata["types"][loop.index0] }}) as {{ metadata["names"][loop.index0] }} {{',' if not loop.last}}
                {% endfor %}
            {% else %}
            ({{ row|join(", ")}}) {{',' if not loop.last}}
            {% endif %}
            {% endif %}
        {% endfor %}
        ]
    )
    )
{% endmacro %}

{% macro default__sql_values(data, metadata, table_alias) %}

    {% set has_types = metadata.get("types", [])|length > 0 %}
    {% set has_names = metadata.get("names", [])|length > 0 %}
    (
        values
        {% for row in data -%}
            {% if has_types %}
            {% set outer_loop = loop %}
            (
            {% for col in row -%}
                cast( {{ col }} as {{ metadata["types"][loop.index0] }}) {{',' if not loop.last}}
            {%- endfor %}
            )
            {% else %}
            ({{ row|join(", ")}}) {{',' if not loop.last}}
            {% endif %}
        {% endfor %}
    ) as {{ table_alias }}
    {{ "(" ~ metadata["names"]|join(",") ~ ")" if has_names }}
{% endmacro %}
