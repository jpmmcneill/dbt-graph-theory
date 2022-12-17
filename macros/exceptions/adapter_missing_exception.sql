{% macro adapter_missing_exception() %}

  {% set supported_adapters = [
  "dbt_postgres",
  "dbt_snowflake"
] %}

  {{- exceptions.raise_compiler_error(
    "This package only supports the following adapters:\n" ~ 
    "- " ~ supported_adapters | join(",\n- ") ~ "\n" ~ 
    "To increase adapter support, please submit an issue or a pull request against https://github.com/jpmmcneill/dbt-graph-theory "
    ) -}}
{% endmacro %}
