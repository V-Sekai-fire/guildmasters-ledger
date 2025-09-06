-- TimescaleDB Optimization Script for the AriaState Bitemporal Schema
-- Version: 2.0
-- Date: 2025-09-05
--
-- This script should be run AFTER the database is created and TimescaleDB extension is enabled.
-- It enables TimescaleDB's native compression on the bitemporal facts table to
-- significantly reduce storage and improve query performance for time-series data.

-- -----------------------------------------------------------------------------
-- Step 0: Ensure the TimescaleDB Extension is Active
-- -----------------------------------------------------------------------------
-- This command will create the extension if it doesn't already exist in the
-- database. It's safe to run even if it's already installed.

CREATE EXTENSION IF NOT EXISTS timescaledb;

-- -----------------------------------------------------------------------------
-- Step 1: Optimize the 'facts' Table (Main Bitemporal Facts Table)
-- -----------------------------------------------------------------------------

-- 1a. Convert the table to a TimescaleDB hypertable, partitioned by 'recorded_at'.
-- This is the most logical time dimension for partitioning as it represents
-- when the fact was recorded in the system. Chunks will be created for every 7 days.
SELECT create_hypertable('facts', 'recorded_at', chunk_time_interval => INTERVAL '7 days');

-- 1b. Enable and configure compression.
-- We specify 'compress_orderby' to physically sort the data on disk by predicate
-- and subject. This groups related facts together and dramatically
-- improves compression ratios and query speed for lookups on specific entities.
ALTER TABLE facts SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'predicate, subject'
);

-- 1c. Add a policy to automatically compress data chunks older than 1 month.
-- This keeps recent, frequently modified data uncompressed for faster writes,
-- while older, historical data is compressed for storage efficiency.
SELECT add_compress_chunks_policy('facts', INTERVAL '1 month');

-- -----------------------------------------------------------------------------
-- Step 2: Additional TimescaleDB Optimizations
-- -----------------------------------------------------------------------------

-- 2a. Enable TimescaleDB's native partitioning for better query performance
-- This creates additional indexes optimized for time-series queries
SELECT add_dimension('facts', 'valid_from', chunk_time_interval => INTERVAL '7 days');

-- 2b. Create continuous aggregates for common time-series queries
-- (Optional: Uncomment if you need pre-aggregated views for performance)

-- CREATE MATERIALIZED VIEW facts_hourly
-- WITH (timescaledb.continuous) AS
-- SELECT
--     time_bucket('1 hour', recorded_at) AS bucket,
--     predicate,
--     subject,
--     COUNT(*) AS fact_count
-- FROM facts
-- GROUP BY bucket, predicate, subject
-- WITH NO DATA;

-- 2c. Add retention policy for very old data (optional)
-- This automatically drops chunks older than 1 year to manage storage
-- SELECT add_retention_policy('facts', INTERVAL '1 year');

-- -----------------------------------------------------------------------------
-- Step 3: Verify TimescaleDB Setup
-- -----------------------------------------------------------------------------

-- Check that TimescaleDB is properly configured
SELECT
    hypertable_name,
    num_chunks,
    compression_enabled,
    compression_chunk_count
FROM timescaledb_information.hypertables
WHERE hypertable_name = 'facts';

-- Check compression status
SELECT
    chunk_name,
    compression_status,
    uncompressed_heap_size,
    compressed_heap_size
FROM timescaledb_information.chunks
WHERE hypertable_name = 'facts'
ORDER BY range_start DESC
LIMIT 10;
