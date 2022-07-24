# Integration Test Models

Because of postgres limitations, model and seed names need to be kept below 51 characters (63 characters is the postgres limit, and `dbt` needs to be able to add the `__dbt_backup` suffix).

For this reason, model and seed names might sometimes have abbreviations:

```yaml
<n>_sg: N subgraphs (the number of subgraphs in the given graph) 
ne: No edges (ie. no vertices are connected)
gid: Graph id (ie. the model has a graph_id defined)
nd: No data (ie. this is an empty table)
```
