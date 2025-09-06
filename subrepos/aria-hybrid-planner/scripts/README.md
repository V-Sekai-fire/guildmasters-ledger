# Database Setup Scripts

This directory contains scripts for setting up and managing the AriaState database environment.

## setup_database.sh

**Purpose**: Complete database setup and cleanup script for AriaState with TimescaleDB support.

**Features**:
- ✅ PostgreSQL service verification
- ✅ TimescaleDB extension installation check
- ✅ Database cleanup (removes existing test databases)
- ✅ User and database creation
- ✅ TimescaleDB extension setup
- ✅ Ecto migration execution
- ✅ Hypertable verification
- ✅ Connection testing

**Usage**:
```bash
# Make executable (first time only)
chmod +x scripts/setup_database.sh

# Run the setup
./scripts/setup_database.sh
```

**What it does**:
1. Checks if PostgreSQL is running
2. Verifies TimescaleDB is installed
3. Cleans up any existing `aria_test` database and `aria_user`
4. Creates fresh database and user
5. Enables TimescaleDB extension
6. Runs Ecto migrations (including TimescaleDB hypertable setup)
7. Verifies hypertable configuration
8. Tests database connectivity

**Expected Output**:
```
🗄️  Setting up PostgreSQL database for AriaState...
🚀 Starting AriaState Database Setup
==================================
✅ Database cleanup completed
✅ Database and user created
✅ TimescaleDB extension enabled
✅ Migrations completed
✅ Facts table is properly configured as a TimescaleDB hypertable
✅ Database connection successful
🎉 Database setup completed successfully!
```

**Post-Setup**:
After running the script, you can:
- Run tests: `mix test`
- Run performance benchmarks: `mix test test/aria_state/postgres_iops_test.exs`
- Verify hypertable status manually

**Troubleshooting**:
- If PostgreSQL isn't running: `sudo systemctl start postgresql`
- If TimescaleDB isn't installed: The script will automatically install it using the correct repository
- If script fails: Check PostgreSQL logs at `/var/lib/pgsql/data/log/`

**Database Configuration**:
- Database: `aria_test`
- Users: `aria_user` (application), `fire` (current user)
- Authentication: Socket-based (no password required)
- Extensions: TimescaleDB enabled
- Hypertables: `facts` table configured for time-series optimization
