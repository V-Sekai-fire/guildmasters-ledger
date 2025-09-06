# **R25W1900003 - Switch to Ordinary PostgreSQL Schema**

**Status:** Approved | **Date:** September 6, 2025

## **Context**
Bitemporal 6NF schema is overly complex for Guildmaster's Ledger game requirements. Need simple fact storage supporting HTN planning `get_fact`/`set_fact` API without historical versioning complexity.

## **Decision**
Replace bitemporal 6NF with simple `facts` table supporting direct API compatibility: `get_fact` → `SELECT`, `set_fact` → `INSERT ON CONFLICT UPDATE`.

## **Success Criteria**
Schema supports HTN planning API operations, maintains game state persistence, eliminates bitemporal complexity, preserves query performance.

## **Timeline**
Complete schema migration by September 10, update persistence layer by September 12, validate API compatibility by September 14.

## **Next Steps**
1. Create simple facts table with (predicate, subject, value) structure
2. Update Elixir persistence layer for direct SQL queries
3. Delete bitemporal_6nf_postgres.sql file
4. Test HTN planning API compatibility
5. Update related decision records
