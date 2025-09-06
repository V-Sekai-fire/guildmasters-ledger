# **R25W1900006 - Storage Technology Selection: PostgreSQL vs SQLite vs FoundationDB**

**Status:** Proposed | **Date:** September 6, 2025

## **Context**

Need to select optimal storage technology for Guildmaster's Ledger supporting 1000+ concurrent heroes with HTN planning integration.

## **Decision**

Evaluate PostgreSQL, SQLite, and FoundationDB for production deployment based on concurrency, performance, and operational requirements.

## **Success Criteria**

**Targets:** Support 1000+ concurrent operations, <5ms latency (95th percentile), ACID compliance, HTN planner compatibility. **Go/No-Go:** GO (meets 3+ targets), REVIEW (meets 2 targets), NO-GO (fails 2+ targets).

## **Timeline**

Week 1: Benchmark each technology with game workloads. Week 2: Compare results and operational assessment.

## **Next Steps**

1. Set up PostgreSQL, SQLite, and FoundationDB test environments
2. Run standardized benchmarks (hero state updates, HTN queries, concurrent operations)
3. Evaluate operational requirements (deployment, monitoring, scaling)
4. Compare total cost of ownership and maintenance complexity
5. Make final technology selection based on performance and operational fit
