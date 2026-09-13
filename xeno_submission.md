# Xeno Data Analyst Take-Home: Comm-Log Send Reconciliation

## Result

For merchant `501` in October 2026, the reconciled `target_base` is **22**.

## Reconciliation bridge

| Step | Description | Result | Reason |
| --- | --- | ---: | --- |
| 0 | Count all in-scope communication-log rows | 30 | This is the most direct starting point: all merchant 501, October 2026, Campaign (`communication_type = '2'`) send attempts. |
| 1 | Keep successfully delivered attempts only (`delivery_status = 900`) | 26 | Four rows have `delivery_status = 1100`, which represents a failed attempt rather than a customer reached. |
| 2 | Keep only reportable campaigns | 22 | Campaign `9004` contributes four delivered rows, but its `creation_status` is `approval_awaiting`. The data dictionary says a campaign is reportable only when creation is finalized and processing is `processed`; therefore these four rows cannot enter Finance reporting. |
| Final validation | Apply retry-family counting semantics | 22 | The eligible retry families contribute 10 (root `9001`) and 5 (root `9201`) distinct reached customers. Standalone campaign `9101` contributes 7 delivered events. This does not change this dataset's numeric total after Steps 1-2, but it is necessary to implement the metric correctly rather than rely on an accidental row count. |

## SQL

Run the contents of `xeno_final_query.sql` against `comm_log.db`. It returns one row with `target_base = 22`.

The query deliberately resolves each campaign to its root with a recursive CTE. For a retry family, it counts a customer once across the entire chain. For a campaign with no retries at all, it counts each delivered log event, preserving the valid second send to customer `C20` in campaign `9101`.

## Data observation

The most surprising feature was that a completed send pipeline does not by itself make a campaign reportable: campaign `9004` is `processed` and has four delivered communication-log rows, yet it remains excluded because its approval workflow is still pending. I also checked the retry chains rather than deduplicating every repeated customer globally. That matters because repeated customers have different meanings here: `C2`, `C3`, and `D1` are retries within a communication family and must be collapsed if they have multiple successful attempts, whereas `C20` was independently re-targeted in a standalone campaign and both delivered events count.
