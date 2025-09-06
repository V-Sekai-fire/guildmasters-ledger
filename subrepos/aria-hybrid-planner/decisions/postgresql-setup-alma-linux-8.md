# Decision: PostgreSQL Setup on Alma Linux 8

## Context

The AriaState bitemporal storage system requires a robust PostgreSQL setup for production use. Alma Linux 8 provides a stable, enterprise-grade platform for running PostgreSQL. This decision document outlines the proper setup procedure for PostgreSQL on Alma Linux 8 to ensure optimal performance, security, and reliability.

## Decision

We will use PostgreSQL 15 (or latest stable version) on Alma Linux 8 with the following configuration approach:

### Installation Method
- Use Alma Linux 8's official PostgreSQL module instead of compiling from source
- Enable the PostgreSQL 15 module for long-term support
- Install additional contrib packages for extended functionality

### Configuration Strategy
- Use dedicated PostgreSQL configuration files
- Implement connection pooling with PgBouncer
- Configure proper logging and monitoring
- Set up automated backups with pgBackRest

## Installation Steps

### 1. System Preparation

```bash
# Update system packages
sudo dnf update -y

# Install EPEL repository for additional packages
sudo dnf install -y epel-release

# Install required system packages
sudo dnf install -y wget curl vim htop iotop sysstat

# Disable SELinux for PostgreSQL compatibility (optional, but recommended for development)
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
```

### 2. PostgreSQL Installation

```bash
# Reset any existing PostgreSQL modules
sudo dnf module reset postgresql -y

# Disable PostgreSQL module to allow PGDG packages
sudo dnf -qy module disable postgresql

# Install PostgreSQL server and additional packages
sudo dnf install -y postgresql-server postgresql-contrib postgresql-devel

# Install TimescaleDB
# Add PostgreSQL repository first
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Add TimescaleDB repository
sudo tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/8/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

# Update repository list
sudo dnf update -y

# Install TimescaleDB
sudo dnf install -y timescaledb-2-postgresql-15

# Install development tools
sudo dnf groupinstall -y "Development Tools"
```

### 3. Initialize Database

```bash
# Initialize PostgreSQL database
sudo postgresql-setup --initdb

# Start and enable PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify service status
sudo systemctl status postgresql
```

### 4. User and Database Setup

```bash
# Switch to postgres user
sudo -u postgres bash

# Create application database and user
createdb aria_production
createuser --createdb --login aria_user

# Grant privileges (no password needed for socket authentication)
psql -c "GRANT ALL PRIVILEGES ON DATABASE aria_production TO aria_user;"

# Exit postgres user shell
exit
```

### 5. TimescaleDB Setup

```bash
# Enable TimescaleDB extension in PostgreSQL
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

# Configure TimescaleDB for the application database
sudo -u postgres psql -d aria_production -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

# Verify TimescaleDB installation
sudo -u postgres psql -d aria_production -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'timescaledb';"

# Run TimescaleDB optimizations (see decisions/timescaledb_optimization.sql)
# This will convert the facts table to a hypertable with compression
sudo -u postgres psql -d aria_production -f /path/to/aria-hybrid-planner/decisions/timescaledb_optimization.sql
```

### 6. Run Database Setup Script

```bash
# Use the automated setup script (recommended)
./scripts/setup_database.sh

# Or manually run the steps:
# mix ecto.migrate
```

### 7. Manual Migration Steps (Alternative)

If you prefer to run the steps manually:

```bash
# Run Ecto migrations to set up the database schema
mix ecto.migrate

# The migrations will:
# 1. Create the facts table with bitemporal schema
# 2. Enable TimescaleDB optimizations (hypertable, compression, policies)
```

### 6. Configuration

#### PostgreSQL Main Configuration (`/var/lib/pgsql/data/postgresql.conf`)

```ini
# Connection Settings
listen_addresses = 'localhost,127.0.0.1'
port = 5432
max_connections = 100
shared_preload_libraries = 'timescaledb,pg_stat_statements'

# Memory Settings (adjust based on server RAM)
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Checkpoint Settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Logging
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_statement = 'ddl'
log_duration = on
log_lock_waits = on
log_temp_files = 0

# Performance Tuning
random_page_cost = 1.1
effective_io_concurrency = 200
```

#### pg_hba.conf Configuration (`/var/lib/pgsql/data/pg_hba.conf`)

```ini
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   aria_production aria_user                               peer
host    aria_production aria_user       127.0.0.1/32            md5
host    aria_production aria_user       ::1/128                 md5
```

### 6. Security Setup

```bash
# Create SSL certificates (optional but recommended)
sudo -u postgres openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=localhost"
sudo chmod 600 /var/lib/pgsql/data/server.key
sudo chown postgres:postgres /var/lib/pgsql/data/server.crt /var/lib/pgsql/data/server.key

# Enable SSL in postgresql.conf
echo "ssl = on" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
echo "ssl_cert_file = 'server.crt'" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
echo "ssl_key_file = 'server.key'" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
```

### 7. Performance Monitoring Setup

```bash
# Install monitoring tools
sudo dnf install -y pg_stat_statements pg_buffercache pg_stat_kcache

# Enable pg_stat_statements in postgresql.conf
echo "shared_preload_libraries = 'pg_stat_statements'" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
echo "pg_stat_statements.track = all" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
echo "pg_stat_statements.max = 10000" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
```

### 8. Backup Setup with pgBackRest

```bash
# Install pgBackRest
sudo dnf install -y pgbackrest

# Create backup configuration
sudo mkdir -p /var/lib/pgbackrest
sudo chown postgres:postgres /var/lib/pgbackrest

# Configure pgBackRest (/etc/pgbackrest.conf)
cat << EOF | sudo tee /etc/pgbackrest.conf
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
repo1-retention-diff=6
process-max=2
log-level-console=info
log-level-file=debug

[aria_production]
pg1-path=/var/lib/pgsql/data
pg1-port=5432
pg1-user=postgres
EOF

# Initialize backup repository
sudo -u postgres pgbackrest stanza-create --stanza=aria_production
```

### 9. Firewall Configuration

```bash
# Allow PostgreSQL port (if remote access needed)
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload
```

### 10. Service Management

```bash
# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# Set up log rotation
sudo tee /etc/logrotate.d/postgresql << EOF
/var/lib/pgsql/data/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    create 0600 postgres postgres
    postrotate
        /bin/kill -HUP \`cat /var/lib/pgsql/data/postmaster.pid 2>/dev/null\` 2>/dev/null || true
    endscript
}
EOF
```

## Testing the Setup

### Basic Connectivity Test

```bash
# Test local connection
psql -h localhost -U aria_user -d aria_production

# Test application connection (from Elixir)
mix test test/aria_state/real_db_test.exs
```

### Performance Benchmarking

```bash
# Run pgBench for performance testing
sudo -u postgres pgbench -i -s 10 aria_production
sudo -u postgres pgbench -c 10 -j 2 -t 1000 aria_production
```

## Monitoring and Maintenance

### Key Metrics to Monitor

1. **Connection Pool Usage**
2. **Query Performance** (via pg_stat_statements)
3. **Disk I/O and Space Usage**
4. **Replication Lag** (if using streaming replication)
5. **Lock Wait Times**

### Regular Maintenance Tasks

```bash
# Daily: Update statistics
sudo -u postgres psql -d aria_production -c "VACUUM ANALYZE;"

# Weekly: Full backup
sudo -u postgres pgbackrest backup --stanza=aria_production --type=full

# Monthly: Reindex (if needed)
sudo -u postgres psql -d aria_production -c "REINDEX DATABASE aria_production;"
```

## Alternatives Considered

### Option 1: Compile from Source
- **Pros**: Latest features, custom optimizations
- **Cons**: Complex maintenance, dependency management
- **Decision**: Rejected due to operational complexity

### Option 2: Docker Container
- **Pros**: Easy deployment, isolation
- **Cons**: Resource overhead, persistence concerns
- **Decision**: Rejected for production use, acceptable for development

### Option 3: PostgreSQL from AlmaLinux AppStream
- **Pros**: Native integration, automatic updates
- **Cons**: May not have latest features
- **Decision**: Chosen for stability and ease of maintenance

## Risks and Mitigations

### Risk 1: Data Loss
- **Mitigation**: Regular backups with pgBackRest, WAL archiving
- **Testing**: Regular restore testing

### Risk 2: Performance Degradation
- **Mitigation**: Monitoring with pg_stat_statements, regular tuning
- **Testing**: Performance benchmarking

### Risk 3: Security Vulnerabilities
- **Mitigation**: Regular updates, SSL encryption, minimal privileges
- **Testing**: Security audits

## Implementation Timeline

1. **Week 1**: Infrastructure setup and PostgreSQL installation
2. **Week 2**: Configuration tuning and security setup
3. **Week 3**: Backup configuration and testing
4. **Week 4**: Application integration and performance testing

## Success Criteria

- [ ] PostgreSQL 15 installed and running on Alma Linux 8
- [ ] TimescaleDB extension installed and configured
- [ ] Database accessible via TCP on port 5432
- [ ] SSL encryption enabled for connections
- [ ] Automated backups configured and tested
- [ ] Performance benchmarks meet requirements (>1000 TPS)
- [ ] Monitoring tools operational
- [ ] Application successfully connects and operates

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/15/)
- [TimescaleDB Documentation](https://docs.timescale.com/)
- [AlmaLinux Documentation](https://almalinux.org/docs/)
- [pgBackRest Documentation](https://pgbackrest.org/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
