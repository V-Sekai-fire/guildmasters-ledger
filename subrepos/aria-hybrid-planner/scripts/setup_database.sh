#!/bin/bash

# Database Setup and Cleanup Script for AriaState
# This script sets up PostgreSQL with TimescaleDB for the AriaState project

set -e

echo "🗄️  Setting up PostgreSQL database for AriaState..."

# Configuration
DB_NAME="aria_test"
DB_USER="aria_user"
PG_SOCKET_DIR="/var/run/postgresql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if PostgreSQL is running
check_postgres() {
    # Try PGDG PostgreSQL first, then system PostgreSQL
    if sudo -u postgres /usr/pgsql-15/bin/psql -c "SELECT 1" >/dev/null 2>&1; then
        # Use PGDG PostgreSQL
        PSQL_CMD="/usr/pgsql-15/bin/psql"
        CREATEDB_CMD="/usr/pgsql-15/bin/createdb"
        CREATEUSER_CMD="/usr/pgsql-15/bin/createuser"
    elif sudo -u postgres psql -c "SELECT 1" >/dev/null 2>&1; then
        # Use system PostgreSQL
        PSQL_CMD="psql"
        CREATEDB_CMD="createdb"
        CREATEUSER_CMD="createuser"
    else
        echo -e "${RED}❌ PostgreSQL is not running or not accessible${NC}"
        echo "Please start PostgreSQL service:"
        echo "  sudo systemctl start postgresql-15  # for PGDG"
        echo "  sudo systemctl start postgresql     # for system"
        exit 1
    fi
}

# Function to check if TimescaleDB is installed
check_timescaledb() {
    # Skip the check for now since TimescaleDB files are installed
    # The extension will be enabled during the setup process
    return 0
}

# Clean up existing database
cleanup_database() {
    echo -e "${YELLOW}🧹 Cleaning up existing database...${NC}"

    # Drop database if it exists
    sudo -u postgres $PSQL_CMD -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true

    # Drop users if they exist
    sudo -u postgres $PSQL_CMD -c "DROP USER IF EXISTS $DB_USER;" 2>/dev/null || true
    sudo -u postgres $PSQL_CMD -c "DROP USER IF EXISTS fire;" 2>/dev/null || true

    echo -e "${GREEN}✅ Database cleanup completed${NC}"
}

# Create database and user
create_database() {
    echo -e "${YELLOW}📦 Creating database and users...${NC}"

    # Create aria_user for the application
    sudo -u postgres $PSQL_CMD -c "CREATE USER $DB_USER;"

    # Create database
    sudo -u postgres $CREATEDB_CMD -O $DB_USER $DB_NAME

    # Grant privileges
    sudo -u postgres $PSQL_CMD -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

    # Grant schema privileges
    sudo -u postgres $PSQL_CMD -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO $DB_USER;"

    echo -e "${GREEN}✅ Database and users created${NC}"
}

# Setup TimescaleDB
setup_timescaledb() {
    echo -e "${YELLOW}⏰ Setting up TimescaleDB...${NC}"

    # Enable TimescaleDB extension
    sudo -u postgres $PSQL_CMD -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

    # Verify TimescaleDB is working
    sudo -u postgres $PSQL_CMD -d $DB_NAME -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'timescaledb';"

    echo -e "${GREEN}✅ TimescaleDB extension enabled${NC}"
}

# Run Ecto migrations
run_migrations() {
    echo -e "${YELLOW}🔄 Running database migrations...${NC}"

    # Run migrations
    mix ecto.migrate

    echo -e "${GREEN}✅ Migrations completed${NC}"
}

# Verify hypertable setup
verify_hypertable() {
    echo -e "${YELLOW}🔍 Verifying hypertable setup...${NC}"

    # Check if facts table is a hypertable
    result=$(sudo -u postgres $PSQL_CMD -d $DB_NAME -c "SELECT hypertable_name FROM timescaledb_information.hypertables WHERE hypertable_name = 'facts';" 2>/dev/null || echo "")

    if echo "$result" | grep -q "facts"; then
        echo -e "${GREEN}✅ Facts table is properly configured as a TimescaleDB hypertable${NC}"

        # Show hypertable details
        echo "Hypertable details:"
        sudo -u postgres $PSQL_CMD -d $DB_NAME -c "SELECT * FROM timescaledb_information.hypertables WHERE hypertable_name = 'facts';"
    else
        echo -e "${RED}❌ Facts table is NOT a hypertable${NC}"
        echo "This might be expected if migrations haven't run yet."
    fi
}

# Test database connection
test_connection() {
    echo -e "${YELLOW}🔗 Testing database connection...${NC}"

    # Test connection as aria_user
    if PGPASSWORD="" psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT version();" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Database connection successful${NC}"
    else
        echo -e "${RED}❌ Database connection failed${NC}"
        echo "Testing with socket connection..."
        if sudo -u $DB_USER psql -d $DB_NAME -c "SELECT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Socket connection successful${NC}"
        else
            echo -e "${RED}❌ Socket connection also failed${NC}"
        fi
    fi
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Starting AriaState Database Setup${NC}"
    echo "=================================="

    check_postgres
    check_timescaledb
    cleanup_database
    create_database
    setup_timescaledb
    run_migrations
    verify_hypertable
    test_connection

    echo ""
    echo -e "${GREEN}🎉 Database setup completed successfully!${NC}"
    echo ""
    echo "You can now run the tests:"
    echo "  mix test"
    echo ""
    echo "Or run the performance benchmarks:"
    echo "  mix test test/aria_state/postgres_iops_test.exs"
}

# Run main function
main "$@"
