# **R25W1900003 - Switch from Bitemporal 6NF to Ordinary PostgreSQL Schema**

**Status:** Approved

**Date:** September 6, 2025

**Context:** The bitemporal 6NF PostgreSQL schema implemented in `bitemporal_6nf_postgres.sql` is overly complex for the Guildmaster's Ledger game requirements. The game needs simple fact storage that supports the HTN planning system's `get_fact` and `set_fact` API operations. The bitemporal approach introduces unnecessary complexity for a game that doesn't require historical versioning of facts.

## **Decision**

We will replace the bitemporal 6NF schema with a simple ordinary relational schema consisting of a single `facts` table that directly supports the planning API's `get_fact` and `set_fact` operations.

### New Schema

```sql
CREATE TABLE facts (
    predicate TEXT NOT NULL,
    subject TEXT NOT NULL,
    value TEXT,
    PRIMARY KEY (predicate, subject)
);

-- Indexes for performance
CREATE INDEX idx_facts_predicate ON facts(predicate);
CREATE INDEX idx_facts_subject ON facts(subject);
```

### API Compatibility

The new schema directly supports the planning API:

- **get_fact(state, predicate, subject)** → `SELECT value FROM facts WHERE predicate = ? AND subject = ?`
- **set_fact(state, predicate, subject, value)** → `INSERT INTO facts (predicate, subject, value) VALUES (?, ?, ?) ON CONFLICT (predicate, subject) DO UPDATE SET value = EXCLUDED.value`

## **Consequences**

### **Positive**

- Simpler schema design and maintenance
- Direct compatibility with HTN planning `get_fact`/`set_fact` API
- Better performance for simple fact queries
- Easier debugging and development
- Reduced complexity for game state persistence

### **Negative**

- Loss of bitemporal capabilities (valid time/transaction time)
- No automatic historical versioning of facts
- Manual implementation needed for any temporal queries

### **Related Decisions**

- [R25W1900002](R25W1900002-readme-content-migration.md) - README content migration (update persistence section)
- [R25W1900001](R25W1900001-v-sekai-september-jam-guildmasters-ledger.md) - Main game concept (update persistence references)
- [R25W1398085](R25W1398085-unified-durative-action-specification-and-planner-standardization.md) - HTN planning specification (API compatibility confirmed)

## **Implementation**

1. Delete `bitemporal_6nf_postgres.sql`
2. Create new `facts` table as shown above
3. Update Elixir persistence layer to use simple SQL queries
4. Update decision records to reflect new schema
5. Test planning API compatibility
