---
title: "Debugging high-cardinality metrics in Prometheus"
date: 2025-03-05
tag: observability
---

Our Prometheus instance started OOMing every few days. The usual suspects —
long retention, too many targets — checked out fine. The actual cause took
longer to find: a single metric with unbounded label cardinality.

### Finding the offender

The `prometheus_tsdb_symbol_table_size_bytes` metric going up is a
leading indicator, but doesn't tell you which metric is responsible.
The TSDB status page does:

```
http://prometheus:9090/tsdb-status
```

It lists the top 10 metrics by series count, head chunks, and memory.
Ours had one metric at 4 million active series. Normal services have a few
thousand.

### The root cause

A developer had added a `request_id` label to a counter — effectively
making every HTTP request its own unique time series. Prometheus stores
every unique label combination as a separate series. A label with
unbounded values is a cardinality bomb.

```yaml
# Bad
http_requests_total{method="GET", path="/api/users", request_id="abc-123"} 1

# Good
http_requests_total{method="GET", path="/api/users", status="200"} 42
```

### The fix

We dropped the label at the recording rule level while the developer
fixed the instrumentation:

```yaml
- record: http_requests_total_safe
  expr: sum without(request_id) (http_requests_total)
```

Then we added a `metric_relabel_configs` rule in the scrape config to
drop the label at ingest time as a long-term guard.

### Takeaway

High cardinality is the most common cause of Prometheus memory issues.
Label values should come from a bounded set — status codes, HTTP methods,
service names. Never user IDs, request IDs, or timestamps.
