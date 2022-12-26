{% macro sql_values(data=[],metadata={"names": [], "types": []}, table_alias = "v") %}
{#
    sql_values is a list of ordered lists with the relevant sql_values.
    metadata is a dict with names and types as the two keys. Ordering is same as sql_values
#}
    {{ return(adapter.dispatch("sql_values", macro_namespace="dbt_graph_theory")(data, metadata, table_alias)) }}
{% endmacro %}

{% macro bigquery__sql_values(data, metadata, table_alias) %}
    {% set struct_names = [] %}
    
    {% for col in metadata["names"] %}
    {% do struct_names.append(col ~ " " ~ metadata["types"][loop.index0]) %}
    {% endfor %}

    {% set metadata_lengths = [metadata.get("types", [])|length, metadata.get("names", [])|length] %}
    {% set has_metadata = metadata_lengths | max > 0 %}
    {{
        exceptions.raise_compiler_error("You must define both names and types for bigquery or neither (in the metadata argument)")
        if metadata_lengths | max > 0 and metadata_lengths | min == 0
    }}

    {{ exceptions.warn(struct_names) }}
    (
    select * from unnest(
        [
        struct <{{ struct_names|join(", ") if has_metadata }}>
        {% for row in data -%}
            ({{ row|join(", ")}}) {{',' if not loop.last}}
        {% endfor %}
        ]
    )
    )
{% endmacro %}

{% macro default__sql_values(data, metadata, table_alias) %}
    (
        values
        {% for row in data -%}
            {% if metadata.get("types", []) != [] %}
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
    {{ "(" ~ metadata["names"]|join(",") ~ ")" if metadata.get("names", []) != [] }}
{% endmacro %}
