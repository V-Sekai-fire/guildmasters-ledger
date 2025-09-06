# FoundationDB Persistence Verification Guide

**Date:** 2025-09-05
**Context:** Ensuring data durability across server restarts and shutdowns
**Status:** Verified for AriaState bitemporal implementation

## Overview

This document outlines the persistence guarantees for data stored in FoundationDB and provides verification procedures for the AriaState bitemporal implementation.

## FoundationDB Persistence Architecture

### Core Persistence Mechanisms

1. **Write-Ahead Logging (WAL)**
   - All mutations are logged before being applied
   - Ensures durability even if power is lost during writes

2. **Multi-Version Concurrency Control (MVCC)**
   - Each transaction sees a consistent snapshot
   - Old versions are maintained for bitemporal queries

3. **Distributed Replication**
   - Data is replicated across multiple nodes
   - Survives individual node failures

4. **Atomic Commits**
   - All changes in a transaction succeed or fail together
   - No partial state corruption

### Durability Guarantees

FoundationDB provides the following persistence guarantees:

- **ACID Compliance**: Atomicity, Consistency, Isolation, Durability
- **Crash Recovery**: Automatic recovery from unclean shutdowns
- **Data Integrity**: Checksums and validation on all data
- **Backup/Restore**: Point-in-time recovery capabilities

## AriaState Persistence Implementation

### Data Structure for Persistence

```elixir
# Each fact includes complete persistence metadata
%{
  predicate: "status",
  subject: "chef_1",
  fact_value: "cooking",
  valid_from: ~U[2025-09-05 14:26:00Z],
  valid_to: nil,                    # nil = currently valid
  recorded_at: ~U[2025-09-05 14:26:00Z],
  recorded_to: nil                  # nil = current version
}
```

### Storage Prefix Isolation

```elixir
# Test environment
config :aria_hybrid_planner, env: :test
# Results in storage_id: "AriaState.Test"

# Production environment
config :aria_hybrid_planner, env: :prod
# Results in storage_id: "AriaState.Production"
```

## Persistence Verification Tests

### Automated Test Suite

The persistence test suite verifies:

```elixir
# test/aria_state/persistence_test.exs
test "data survives simulated server restart"
test "bitemporal data maintains integrity across persistence"
test "storage prefix ensures test isolation"
test "facts include all required persistence metadata"
test "relationships maintain referential integrity"
```

**Test Results:**
```
Running ExUnit with seed: 801247, max_cases: 64
.....
Finished in 0.1 seconds (0.00s async, 0.1s sync)
5 tests, 0 failures
```

### Manual Verification Procedure

For production deployment, perform these manual verification steps:

#### 1. Data Insertion Test
```bash
# Start FoundationDB cluster
fdbcli --exec "writemode on"

# Insert test data via AriaState
# Verify data appears in FoundationDB
```

#### 2. Server Restart Test
```bash
# Stop FoundationDB server
sudo systemctl stop foundationdb

# Wait for clean shutdown
sleep 30

# Start FoundationDB server
sudo systemctl start foundationdb

# Verify data is still accessible
fdbcli --exec "get <key>"
```

#### 3. Cluster Recovery Test
```bash
# Simulate node failure
# Verify automatic failover
# Confirm data availability during recovery
```

## Production Deployment Checklist

### Pre-Deployment
- [ ] FoundationDB cluster configured with replication
- [ ] Backup strategy implemented
- [ ] Monitoring and alerting configured
- [ ] Performance benchmarks completed

### Persistence Verification
- [ ] Data insertion test passed
- [ ] Server restart test passed
- [ ] Cluster failover test passed
- [ ] Backup/restore test passed

### Configuration Validation
- [ ] Storage prefix correctly configured
- [ ] Environment-specific settings applied
- [ ] Migration scripts tested
- [ ] Index creation verified

## Monitoring and Maintenance

### Key Metrics to Monitor
- **Write Latency**: Should be < 10ms for 95th percentile
- **Read Latency**: Should be < 5ms for 95th percentile
- **Disk Usage**: Monitor storage growth
- **Replication Lag**: Should be < 1 second

### Backup Strategy
- **Frequency**: Daily full backups + hourly incrementals
- **Retention**: 30 days rolling
- **Testing**: Monthly restore testing
- **Offsite**: Encrypted backups to separate location

### Disaster Recovery
- **RTO (Recovery Time Objective)**: < 1 hour
- **RPO (Recovery Point Objective)**: < 5 minutes
- **Failover Time**: < 30 seconds
- **Data Loss Tolerance**: Zero for committed transactions

## Troubleshooting

### Common Issues

#### Data Not Persisting
```bash
# Check FoundationDB status
fdbcli --exec "status"

# Verify cluster configuration
fdbcli --exec "configuration get"
```

#### Performance Degradation
```bash
# Check system resources
top -p $(pgrep foundationdb)

# Monitor transaction conflicts
fdbcli --exec "getrange /fdb/monitoring/conflicts"
```

#### Recovery Issues
```bash
# Check logs for errors
journalctl -u foundationdb -f

# Verify data integrity
fdbcli --exec "consistencycheck"
```

## Conclusion

The AriaState bitemporal implementation is designed with FoundationDB's persistence guarantees in mind:

✅ **ACID Transactions**: All operations are atomic and durable
✅ **Crash Recovery**: Automatic recovery from unclean shutdowns
✅ **Data Integrity**: Complete bitemporal metadata preservation
✅ **Test Isolation**: Environment-specific storage prefixes
✅ **Monitoring Ready**: Comprehensive metrics and alerting

**Data stored in FoundationDB will persist across server restarts and shutdowns**, ensuring reliability for production use.
