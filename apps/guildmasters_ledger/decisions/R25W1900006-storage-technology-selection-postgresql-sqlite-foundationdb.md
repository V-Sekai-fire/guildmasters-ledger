# **R25W1900006 - Storage Technology Selection: PostgreSQL vs SQLite vs FoundationDB**

**Status:** Completed | **Date:** September 6, 2025

## **Context**

Need to select optimal storage technology for Guildmaster's Ledger supporting 1000+ concurrent heroes with HTN planning integration.

## **Decision**

Evaluate PostgreSQL, SQLite, and FoundationDB for production deployment based on concurrency, performance, and operational requirements.

## **Success Criteria**

**Targets:** Support 1000+ concurrent operations, <5ms latency (95th percentile), ACID compliance, HTN planner compatibility. **Go/No-Go:** GO (meets 3+ targets), REVIEW (meets 2 targets), NO-GO (fails 2+ targets).

## **Timeline**

Week 1: Benchmark each technology with game workloads. Week 2: Compare results and operational assessment.

## **Next Steps**

1. Create R25W1900007: PostgreSQL technology analysis and evaluation
2. Create R25W1900008: SQLite technology analysis and evaluation
3. Create R25W1900009: FoundationDB technology analysis and evaluation
4. Create R25W1900010: Implementation and migration strategy
5. Create R25W1900011: Cost analysis and total cost of ownership
6. Consolidate findings and make final technology selection
