# dbt-graph-theory

[![](https://img.shields.io/static/v1?label=dbt-core&message=1.0.0&logo=dbt&logoColor=FF694B&labelColor=5c5c5c&color=047377&style=for-the-badge)](https://github.com/dbt-labs/dbt-core)
[![](https://img.shields.io/static/v1?label=dbt-utils&message=0.8.0&logo=dbt&logoColor=FF694B&labelColor=5c5c5c&color=047377&style=for-the-badge)](https://github.com/dbt-labs/dbt-utils/)

**Note**: README structure inspired by dbt-date and dbt-expectations.

A DBT package designed to help SQL based analysis of graphs.

A [graph](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)) is a structure defined by a set of vertices and edges.

```mermaid
flowchart
  A---B
  A---C
  B---C
  C---D
  B---E
  E---F
  A---F
```

The above is a graph with vertices {A, B, C, D, E, F}, and edges described by the lines between vertices. In the context of this package, this graph is represented by the SQL table:

| edge_id | vertex_1 | vertex_2 |
|:-------:|:--------:|:--------:|
|    1    |     A    |     B    |
|    2    |     A    |     C    |
|    3    |     B    |     C    |
|    4    |     C    |     D    |
|    5    |     B    |     E    |
|    6    |     E    |     F    |
|    7    |     A    |     F    |

In table representation, null vertices represent vertices that are not connected to any other vertices.

The following tables:

| edge_id | vertex_1 | vertex_2 |
|:-------:|:--------:|:--------:|
|    1    |     A    |          |
|    2    |     B    |     C    |

| edge_id | vertex_1 | vertex_2 |
|:-------:|:--------:|:--------:|
|    1    |          |     A    |
|    2    |     B    |     C    |

are equivalent to:

```mermaid
flowchart
  A
  B---C
```

In this package, all rows are considered - meaning that the following tables are equivalent:

| edge_id | vertex_1 | vertex_2 |
|:-------:|:--------:|:--------:|
|    1    |          |     A    |
|    2    |     A    |          |
|    3    |          |          |
|    4    |     A    |     B    |

| edge_id | vertex_1 | vertex_2 |
|:-------:|:--------:|:--------:|
|    1    |     A    |     B    |

This package also supports multiple graphs being represented in the same table:

| graph_id | edge_id | vertex_1 | vertex_2 |
|:--------:|:-------:|:--------:|:--------:|
|     1    |    1    |     A    |     B    |
|     1    |    2    |     A    |     C    |
|     1    |    3    |     B    |     C    |
|     1    |    4    |     C    |     D    |
|     2    |    1    |    A'    |    B'    |
|     2    |    2    |    B'    |    C'    |
|     2    |    3    |    C'    |    D'    |

```mermaid
flowchart
  subgraph 1
  A---B
  A---C
  B---C
  C---D
  end
  subgraph 2
  A'---B'
  B'---C'
  C'---D'
  end
```

While in the example above no vertices were shared between graphs, this is not a strict requirement.

`edge_id` should be unique over the table (when `graph_id` is not defined) or at a `graph_id` level when `graph_id` is defined.

----
## Variables

This package currently has no variables that need to be configured.

----
## Integration Tests (Developers Only)

This section assumes development on a mac, where python3 & postgresql are installed. While this package supports both snowflake and postgres, only postgres integration tests are currently implemented.

### Setting up python environment 

Integration tests for this repository are managed via the `integration_tests` folder.

To set up a python3 virtual environment, run the following in order from the `integration_tests` folder.

```
python3 -m venv ci_venv
source ci_venv/bin/activate
pip install -r requirements.txt
```

To exit the virtual environment, simply run:

```
deactivate
```

### Setting up postgres server 

Integration tests run on a local postgres server. The below assumes postgres has been installed via homebrew.

A postgres server can be spun up with the following:

```
bash bin/setup-postgres    --sets up a postgres server for running integration tests locally
```

Note that both of these silence stdout (ie error / success messages) so you may experience unexpected behaviour. If so - please raise an issue on GitHub.

Once, a postgres server has been setup, it can be started and stopped with the following:

```
bash bin/start-postgres    --starts the postgres server for running integration tests locally
bash bin/stop-postgres    --stops the postgres server for running integration tests locally
```

These can be useful when you want to persist data from previous runs of integration tests but not constantly run a postgres server.

Finally, the postgres server can be destroyed via:

```
bash bin/destroy-postgres    --destroys the postgres server for running integration tests locally
```

### Running dbt

To run dbt, simply run dbt commands as usual, specifying the CI profile & selecting the integration tests:

```
dbt clean
dbt deps
dbt seed --profiles-dir ci_profiles
dbt build -s dbt_graph_theory_integration_tests --profiles-dir ci_profiles
```

The style of integration test is raw data that is seeded and validated against by running a model and running tests that should pass when the expected result is present.

### Viewing local data

To view data generated in the integration tests locally, simply connect to the database and query the given table:

```
psql ci_db
select * from <table>;
...
quit -- to end the server connection
```

All CI models are required to run and pass tests for a merge to be allowed.

----
## Contents

**[Generic tests](#generic-tests)**
  - [graph_is_connected](#graph_is_connected)

**[Macros](#macros)**
  - [largest_connected_subgraph_identifier](#largest_connected_subgraph_identifier)

**[Helper Macros](#helper-macros)**
  - [array_agg](#array_agg)
  - [array_append](#array_append)
  - [array_construct](#array_construct)
  - [array_contains](#array_contains)
## Generic Tests

### [graph_is_connected](tests/generic/graph_is_connected.sql)

Arguments:
- edge_id: the name of the field for the edge_id column in the given table graph representation.
- vertex_1: the name of the field for the vertex_1 column in the given table graph representation.
- vertex_2: the name of the field for the vertex_2 column in the given table graph representation.
- graph_id [Optional, text]: the name of the field for the graph_id column in the given table graph representation.

Usage:
```yaml
models:
  - name: <model_name>
    tests:
      - dbt_graph_theory.graph_is_connected:
          graph_id: ...
          edge_id: ...
          vertex_1: ...
          vertex_2: ...
```

Tests whether the given model (a table representation of a graph) is connected. A connected graph is defined as one where a path exists between any two nodes. As an example, the below graph is not connected:

```mermaid
flowchart
  A---B
  B---C
  D---E
  E---F
  D---F
  E---G
```

## Macros
### [largest_connected_subgraph_identifier](macros/largest_connected_subgraph_identifier.sql)

Arguments:
- input: the input model (inputted as `ref(...)`) or CTE (inputted as a string) with
- edge_id: the name of the field for the edge_id column in the given table graph representation.
- vertex_1: the name of the field for the vertex_1 column in the given table graph representation.
- vertex_2: the name of the field for the vertex_2 column in the given table graph representation.
- graph_id [Optional, text]: the name of the field for the graph_id column in the given table graph representation.

Usage:
```sql
with subgraphs as (
    {{ dbt_graph_theory.largest_connected_subgraph_identifier(
        input=ref('example_model'),
        edge_id='edge_id_field_name',
        vertex_1='vertex_1_field_name',
        vertex_2='vertex_2_field_name',
        graph_id='graph_id_field_name'
    ) }}
)
...
```

```sql
...
subgraphs as (
    {{ dbt_graph_theory.largest_connected_subgraph_identifier(
        input='example_cte',
        edge_id='different_edge_id_field_name',
        vertex_1='different_vertex_1_field_name',
        vertex_2='different_vertex_2_field_name'
    ) }}
)
...
```

This macro groups vertices into the largest connected subgraph that they are a member of.

In the below graph:

```mermaid
flowchart
  A---B
  B---C
  D---E
  E---F
  D---F
  E---G
```

The following table is returned:

| edge_id | vertex_1 | vertex_2 | subgraph_id |  subgraph_members  |
|:-------:|:--------:|:--------:|:-----------:|:------------------:|
|    1    |     A    |     B    |      1      |  ['A', 'B', 'C']   |
|    2    |     B    |     C    |      1      |  ['A', 'B', 'C']   |
|    3    |     D    |     E    |      2      |['D', 'E', 'F', 'G']|
|    4    |     E    |     F    |      2      |['D', 'E', 'F', 'G']|
|    5    |     D    |     F    |      2      |['D', 'E', 'F', 'G']|
|    6    |     E    |     G    |      2      |['D', 'E', 'F', 'G']|

subgraph_id is designed to be unique to both the graph and subgraph level. 

## Helper Macros
Note that the below are designed for internal (ie. dbt-graph-theory) use only. Use them at your own risk!
### [array_agg](macros/utils/array_agg.sql)
Adapter specific macro for aggregating a column into an array.
### [array_append](macros/utils/array_append.sql)
Adapter specific macro for appending a new value into an array.
### [array_construct](macros/utils/array_construct.sql)
Adapter specific macro for constructuring an array from a list of values.
### [array_contains](macros/utils/array_contains.sql)
Adapter specific macro to test whether a value is contained within an array.
