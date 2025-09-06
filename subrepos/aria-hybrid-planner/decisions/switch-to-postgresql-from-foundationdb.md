# Decision: Switch from FoundationDB to PostgreSQL for Database Backend

**Date:** 2025-09-05
**Status:** Implemented
**Deciders:** Development Team
**Consulted:** N/A
**Informed:** N/A

## Context

The project was originally using FoundationDB as the database backend for storing bitemporal data. However, several issues arose:

1. **Compatibility Issues**: FoundationDB adapter had tenancy configuration problems
2. **Setup Complexity**: Required specific FoundationDB cluster setup and configuration
3. **Ecosystem Maturity**: PostgreSQL has more mature tooling and broader community support
4. **TimescaleDB Integration**: PostgreSQL allows for TimescaleDB integration for time-series optimizations

## Decision

We will switch from FoundationDB to PostgreSQL as the primary database backend for the AriaState bitemporal storage system.

### Migration Details

- **From:** FoundationDB with Ecto.Adapters.FoundationDB
- **To:** PostgreSQL with Ecto.Adapters.Postgres
- **Future Enhancement:** TimescaleDB for time-series optimizations

### Implementation Steps

1. **Database Setup**
   - Install PostgreSQL 10+
   - Create test database (`aria_test`)
   - Set up database user with appropriate permissions

2. **Code Changes**
   - Update `config/test.exs` to use PostgreSQL connection settings
   - Change `lib/aria_state/repo.ex` to use `Ecto.Adapters.Postgres`
   - Remove FoundationDB-specific tenancy code
   - Update test files to work with PostgreSQL

3. **Schema Migration**
   - Convert FoundationDB-specific schema definitions to PostgreSQL
   - Ensure bitemporal 6NF structure is maintained
   - Update migration files for PostgreSQL compatibility

4. **Test Updates**
   - Rename `test/aria_state/real_fdb_test.exs` to `test/aria_state/real_db_test.exs`
   - Remove FoundationDB-specific checks
   - Update test to perform actual database operations

## Consequences

### Positive
- **Simplified Setup**: PostgreSQL is easier to install and configure
- **Better Tooling**: More mature development tools and ecosystem
- **TimescaleDB Ready**: Can easily add TimescaleDB for time-series optimizations
- **Broader Compatibility**: Works with standard database tooling

### Negative
- **Migration Effort**: Need to update all database-related code
- **Performance Differences**: May need optimization for PostgreSQL-specific patterns
- **TimescaleDB Optional**: Advanced time-series features require separate installation

### Risks
- **Data Migration**: Existing FoundationDB data would need migration if any exists
- **Query Optimization**: May need to adjust queries for PostgreSQL performance
- **TimescaleDB Learning**: Team needs to learn TimescaleDB if implemented

## Alternatives Considered

1. **Keep FoundationDB**: Maintain current setup despite configuration issues
2. **Use PostgreSQL + TimescaleDB**: Implement both PostgreSQL and TimescaleDB immediately
3. **Use Different Database**: Consider other options like ClickHouse or InfluxDB

## Implementation Status

- ✅ PostgreSQL installed and configured
- ✅ Database user and test database created
- ✅ Project configuration updated
- ✅ Repo adapter changed to PostgreSQL
- ✅ Test file renamed and updated
- ⏳ Run tests to verify functionality
- ⏳ Update decision documentation

## Future Considerations

- **TimescaleDB Integration**: Add TimescaleDB for time-series optimizations
- **Performance Monitoring**: Monitor PostgreSQL performance vs. original FoundationDB setup
- **Migration Tools**: Develop tools for migrating any existing FoundationDB data

## Related Decisions

- [Bitemporal 6NF FoundationDB Schema](bitemporal_6nf_foundationdb.md)
- [Bitemporal 6NF PostgreSQL Schema](bitemporal_6nf_postgres.sql)
- [TimescaleDB Optimization](timescaledb_optimization.sql)
