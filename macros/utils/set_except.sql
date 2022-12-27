{% macro set_except() %}
    {{ return(adapter.dispatch("set_except", macro_namespace="dbt_graph_theory")()) }}
{% endmacro %}

{% macro bigquery__set_except() %}
    except distinct
{% endmacro %}

{% macro default__set_except() %}
    except
{% endmacro %}
