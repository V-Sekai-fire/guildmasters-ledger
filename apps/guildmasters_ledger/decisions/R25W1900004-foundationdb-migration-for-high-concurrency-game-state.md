# **R25W1900004 - FoundationDB Migration for High-Concurrency Game State**

**Status:** Proposed

**Date:** September 6, 2025

## **Context**

The Guildmaster's Ledger game requires supporting 1000+ concurrent heroes on a single machine, comparable to large-scale multiplayer games like Fortnite (100-140 concurrent players). The current PostgreSQL persistence layer uses traditional Ecto schemas with predicate routing to maintain compatibility with the HTN planning system's `get_fact`/`set_fact` API.

### Current PostgreSQL Implementation

- **Schemas:** Hero, Quest, Guild, Entity with binary IDs and UTC timestamps
- **Predicate Routing:** Maps HTN predicates to schema fields (e.g., "hero_status" → Hero.status)
- **Query Patterns:** Complex Ecto queries for fact retrieval and updates
- **Architecture:** Relational database with traditional migrations and indexes

### FoundationDB Characteristics

- **Storage Model:** Distributed key-value store with ACID transactions
- **Tenancy:** Requires EctoFoundationDB.Tenant for multitenancy
- **Migrations:** Online/lazy execution for index management only
- **Query Capabilities:** Limited to Equal and Between operations
- **Data Types:** Erlang term serialization (:erlang.term_to_binary/1)
- **Performance:** High-throughput (1M+ ops/sec) with low latency
- **Indexes:** Built-in secondary indexing system
- **Transactions:** All operations in explicit transactions
- **Watches:** Push notifications for data changes
- **Versionstamps:** Autoincrement functionality

### Scale Requirements

- **Target Concurrency:** 1000+ heroes simultaneously active
- **Workload:** High-frequency state updates (status, location, capabilities)
- **Latency Requirements:** Sub-millisecond response times
- **Data Volume:** Growing with player count and game progression

## **Decision**

We will migrate from PostgreSQL to FoundationDB to meet the high-concurrency requirements of 1000+ simultaneous heroes.

### Rationale

1. **Scale Justification:** FDB's key-value architecture excels at high-throughput concurrent operations
2. **Performance Requirements:** Sub-millisecond latency for 1000+ concurrent state updates
3. **Query Compatibility:** Current HTN predicates can be adapted to FDB's Equal/Between constraints
4. **Future Scalability:** FoundationDB's distributed nature supports horizontal scaling

### Key Design Decisions

1. **Tenant Strategy:** Single tenant for the game world
2. **Schema Preservation:** Maintain current Ecto schemas (Hero, Quest, Guild, Entity) on FoundationDB
3. **Query Compatibility:** Keep existing Ecto query patterns where possible
4. **Migration Approach:** Gradual rollout with PostgreSQL fallback

## **Consequences**

### **Positive**

- **Performance:** 1M+ operations/second with sub-millisecond latency
- **Concurrency:** MVCC handles 1000+ simultaneous transactions efficiently
- **Scalability:** Linear scaling across cores and machines
- **Simplicity:** No complex relational schema maintenance
- **Transactions:** Strong ACID guarantees with optimistic concurrency
- **Future-Proof:** Built for distributed deployment

### **Negative**

- **Query Limitations:** Some complex queries may need adaptation for FDB constraints
- **Migration Complexity:** Schema migration to FoundationDB backend
- **Learning Curve:** New operational patterns and FoundationDB-specific tooling
- **Cost:** Commercial licensing vs PostgreSQL's open-source nature
- **Ecosystem:** Less mature Elixir/Ecto integration compared to PostgreSQL
- **Debugging:** Different debugging patterns for distributed key-value store

### **Risks**

- **HTN Compatibility:** Query pattern changes may break planner assumptions
- **Performance Regression:** If key design doesn't match access patterns
- **Operational Complexity:** Different deployment and monitoring requirements
- **Vendor Lock-in:** Commercial dependency on FoundationDB
- **Migration Rollback:** Complex to revert if issues arise

### **Mitigations**

- **Prototyping:** Test FDB adapter with subset of predicates first
- **Performance Benchmarking:** Compare against current PostgreSQL baseline
- **Gradual Rollout:** Feature flags for incremental migration
- **Fallback Strategy:** Maintain PostgreSQL as backup during transition

## **Implementation**

### Phase 1: Proof of Concept

1. Set up FoundationDB cluster locally
2. Implement EctoFoundationDB adapter
3. Test existing schemas with FoundationDB backend
4. Validate predicate routing compatibility
5. Performance benchmark vs PostgreSQL

### Phase 2: Core Migration

1. **Schema Preservation:**

   - Maintain existing Ecto schemas (Hero, Quest, Guild, Entity)
   - Use EctoFoundationDB adapter for FoundationDB backend
   - Keep current field mappings and validations
   - Preserve binary ID and timestamp patterns

2. **Query Compatibility:**

   ```elixir
   # Existing Ecto queries work with minimal changes
   hero = Repo.get(Hero, hero_id)
   hero_status = hero.status

   # Complex queries adapted for FDB constraints
   heroes_at_location = from(h in Hero,
                           where: h.location == ^target_location,
                           select: h) |> Repo.all()
   ```

3. **Tenant Configuration:**

   ```elixir
   # Single tenant for game world
   tenant = EctoFoundationDB.Tenant.open("game_world")

   # Schema definitions remain familiar
   schema "heroes" do
     field :hero_id, :string
     field :status, :string
     field :location, :string
     field :capabilities, {:array, :string}
     timestamps(type: :utc_datetime_usec)
   end
   ```

### Phase 3: Data Migration

1. Export PostgreSQL data using existing Ecto schemas
2. Migrate schema data directly to FoundationDB backend
3. Validate data integrity with EctoFoundationDB adapter
4. Test HTN planner compatibility with migrated data
5. Performance testing with full dataset

### Phase 4: Production Deployment

1. Feature flag rollout (PostgreSQL primary, FDB secondary)
2. Gradual traffic migration
3. Monitoring and alerting setup
4. Rollback procedures documented
5. PostgreSQL decommissioning

### Technical Implementation Details

#### EctoFoundationDB Integration

- Replace Ecto.Repo with EctoFoundationDB.Repo
- Preserve existing schema definitions with minimal changes
- Maintain current field mappings and validations
- Configure tenant management for single-tenant game world

#### HTN Planner Modifications

- Keep existing predicate routing largely unchanged
- Adapt complex queries to work within FDB's Equal/Between constraints
- Optimize location-based queries using FDB's range capabilities
- Maintain get_fact/set_fact API compatibility

#### Index Strategy

- Leverage FDB's built-in secondary indexes
- Design compound keys for common query patterns
- Monitor index performance and adjust as needed

#### Operational Changes

- FoundationDB cluster management
- Backup and recovery procedures
- Monitoring and observability setup
- Performance tuning guidelines

## **Performance Expectations**

### FoundationDB Advantages

- **Throughput:** 1M+ ops/sec on single machine
- **Latency:** <1ms for key-value operations
- **Concurrency:** Efficient MVCC for 1000+ simultaneous users
- **Scalability:** Linear performance scaling

### Benchmarking Plan

1. **Current Baseline:** Measure PostgreSQL performance with 1000 concurrent heroes
2. **FDB Prototype:** Test equivalent operations in FoundationDB
3. **Load Testing:** Simulate game workload patterns
4. **HTN Integration:** Test planner performance with adapted queries

## **Cost Analysis**

### FoundationDB

- **Licensing:** Commercial license required
- **Infrastructure:** Similar hardware requirements
- **Operational:** Potentially lower operational complexity

### PostgreSQL

- **Licensing:** Open-source (no licensing cost)
- **Infrastructure:** Standard database server
- **Operational:** Mature tooling and expertise available

### Total Cost of Ownership

- **Migration:** Development time and testing
- **Training:** Team learning curve for FDB operations
- **Infrastructure:** Any additional hardware requirements
- **Maintenance:** Ongoing operational differences

## **Related Decisions**

- [R25W1900003](R25W1900003-switch-to-ordinary-postgresql-schema.md) - Switch from bitemporal 6NF to ordinary PostgreSQL schema
- [R25W1398085](R25W1398085-unified-durative-action-specification-and-planner-standardization.md) - HTN planning specification and API standardization
- [R25W1900001](R25W1900001-v-sekai-september-jam-guildmasters-ledger.md) - Main game concept and architecture decisions

## **Success Metrics**

1. **Performance:** Sub-millisecond latency for 1000+ concurrent operations
2. **Compatibility:** HTN planner functions correctly with adapted queries
3. **Reliability:** Zero data loss during migration
4. **Maintainability:** Development velocity maintained post-migration
5. **Scalability:** Linear performance scaling validated

## **Alternatives Considered**

### Option 1: Stay with PostgreSQL

- **Pros:** No migration complexity, proven technology, open-source
- **Cons:** Potential performance limitations at 1000+ concurrency
- **Recommendation:** Not viable given scale requirements

### Option 2: PostgreSQL Optimization

- **Pros:** Stay with familiar technology, potentially sufficient
- **Cons:** May not achieve required performance, complex optimization
- **Recommendation:** Investigate first, but FDB likely superior for this workload

### Option 3: Other Key-Value Stores

- **Options:** Redis, Cassandra, DynamoDB
- **Pros:** Various performance characteristics
- **Cons:** May not match FDB's transactional guarantees
- **Recommendation:** FDB best fits requirements for ACID and distributed capabilities

## **Next Steps**

1. **Week 1:** Set up FoundationDB development environment
2. **Week 2:** Implement proof-of-concept with Hero predicates
3. **Week 3:** Performance benchmarking and HTN compatibility testing
4. **Week 4:** Full migration planning and risk assessment
5. **Week 5-6:** Data migration and production deployment

This migration positions the Guildmaster's Ledger for high-concurrency gameplay while maintaining HTN planner compatibility through careful query adaptation and key design.
