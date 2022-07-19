# dbt-graph-theory

[![](https://img.shields.io/static/v1?label=dbt-core&message=1.0.0&logo=dbt&logoColor=FF694B&labelColor=5c5c5c&color=047377&style=for-the-badge)](https://github.com/dbt-labs/dbt-core)
[![](https://img.shields.io/static/v1?label=dbt-utils&message=0.8.0&logo=dbt&logoColor=FF694B&labelColor=5c5c5c&color=047377&style=for-the-badge)](https://github.com/dbt-labs/dbt-utils/)

README structure inspired by dbt-date and dbt-expectations.

A DBT package designed to help SQL based analysis of graphs.

## Variables

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

## Available Tests

## Available Macros
