#!/bin/bash

echo "=== Standby Initialization Script Starting ==="

# Function to perform base backup
perform_backup() {
  echo "=== Starting Base Backup Process ==="
  
  # Wait for transactional_db to be ready
  until pg_isready -h transactional_db -U postgres; do
    echo 'Waiting for transactional_db...';
    sleep 2;
  done;
  
  echo 'Database is ready, waiting for replicator role...';
  sleep 10;
  
  # Wait for replicator role
  until PGPASSWORD=replicator_password psql -h transactional_db -U replicator -d postgres -c 'SELECT 1' 2>/dev/null; do
    echo 'Waiting for replicator role to be created...';
    sleep 5;
  done;
  
  echo 'Replicator role is ready, starting base backup';
  BACKUP_DIR="/pg_basebackups/backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  
  PGPASSWORD=replicator_password pg_basebackup -h transactional_db -U replicator -D "$BACKUP_DIR" -Ft -z -P -v;
  
  if [ $? -eq 0 ]; then
    echo 'Setting permissions on backup files...';
    chmod -R 755 "$BACKUP_DIR";
    chown -R 999:999 "$BACKUP_DIR";
    echo "Backup completed successfully at: $BACKUP_DIR"
    return 0
  else
    echo "ERROR: Backup failed!"
    rm -rf "$BACKUP_DIR"
    return 1
  fi
}

# Function to get primary database system identifier
get_primary_identifier() {
  echo "Fetching primary database system identifier..."
  PGPASSWORD=postgres psql -h transactional_db -U postgres -d postgres -t -c "SELECT system_identifier FROM pg_control_system();" 2>/dev/null | tr -d ' '
}

# Function to validate backup against primary
validate_backup() {
  local backup_dir=$1
  
  if [ ! -f "$backup_dir/base.tar.gz" ] && [ ! -f "$backup_dir/base.tar" ]; then
    echo "Backup validation failed: No base backup file found"
    return 1
  fi
  
  # Try to get primary identifier
  PRIMARY_ID=$(get_primary_identifier)
  
  if [ -z "$PRIMARY_ID" ]; then
    echo "Warning: Could not fetch primary identifier, skipping validation"
    return 0
  fi
  
  echo "Primary database system identifier: $PRIMARY_ID"
  
  # Extract a small portion to check pg_control
  TEMP_DIR=$(mktemp -d)
  if [ -f "$backup_dir/base.tar.gz" ]; then
    tar -xzf "$backup_dir/base.tar.gz" -C "$TEMP_DIR" global/pg_control 2>/dev/null || true
  elif [ -f "$backup_dir/base.tar" ]; then
    tar -xf "$backup_dir/base.tar" -C "$TEMP_DIR" global/pg_control 2>/dev/null || true
  fi
  
  if [ -f "$TEMP_DIR/global/pg_control" ]; then
    # Use pg_controldata if available
    BACKUP_ID=$(pg_controldata "$TEMP_DIR" 2>/dev/null | grep "Database system identifier:" | awk '{print $4}')
    rm -rf "$TEMP_DIR"
    
    if [ -n "$BACKUP_ID" ] && [ "$BACKUP_ID" != "$PRIMARY_ID" ]; then
      echo "Backup validation failed: Identifier mismatch (backup: $BACKUP_ID, primary: $PRIMARY_ID)"
      return 1
    fi
  else
    rm -rf "$TEMP_DIR"
    echo "Warning: Could not validate backup identifier"
  fi
  
  return 0
}

# Check if data directory exists and has valid data
if [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
  echo 'No data directory found, need to restore from backup...'

  # Find the latest backup
  LATEST_BACKUP=$(ls -td /pg_basebackups/backup_* 2>/dev/null | head -1)
  
  NEED_NEW_BACKUP=false
  
  if [ -z "$LATEST_BACKUP" ]; then
    echo 'No existing backup found, will create new backup...'
    NEED_NEW_BACKUP=true
  else
    echo "Found existing backup: $LATEST_BACKUP"
    echo "Validating backup against current primary..."
    
    if ! validate_backup "$LATEST_BACKUP"; then
      echo "Backup validation failed - will create new backup"
      NEED_NEW_BACKUP=true
      
      # Archive old backups instead of deleting
      echo "Archiving old backups..."
      ARCHIVE_DIR="/pg_basebackups/archive_$(date +%Y%m%d_%H%M%S)"
      mkdir -p "$ARCHIVE_DIR"
      mv /pg_basebackups/backup_* "$ARCHIVE_DIR/" 2>/dev/null || true
    else
      echo "Backup validation successful"
    fi
  fi
  
  # Create new backup if needed
  if [ "$NEED_NEW_BACKUP" = true ]; then
    if ! perform_backup; then
      echo "ERROR: Failed to create backup!"
      exit 1
    fi
    LATEST_BACKUP=$(ls -td /pg_basebackups/backup_* | head -1)
  fi

  echo "Using backup: $LATEST_BACKUP"
  
  # List contents to verify
  echo "Backup directory contents:"
  ls -lah "$LATEST_BACKUP/" || echo "Failed to list directory"

  # Extract base backup
  if [ -f "$LATEST_BACKUP/base.tar.gz" ]; then
    echo 'Found base.tar.gz, extracting to /var/lib/postgresql/data ...'
    tar -xzf "$LATEST_BACKUP/base.tar.gz" -C /var/lib/postgresql/data
    echo 'Base extraction complete'
  elif [ -f "$LATEST_BACKUP/base.tar" ]; then
    echo 'Found base.tar, extracting...'
    tar -xf "$LATEST_BACKUP/base.tar" -C /var/lib/postgresql/data
    echo 'Base extraction complete'
  else
    echo 'ERROR: base.tar.gz NOT found in backup directory!'
    echo "Listing what we found:"
    ls -la "$LATEST_BACKUP/"
    exit 1
  fi

  # Extract pg_wal
  if [ -f "$LATEST_BACKUP/pg_wal.tar.gz" ]; then
    echo 'Found pg_wal.tar.gz, extracting WAL...'
    mkdir -p /var/lib/postgresql/data/pg_wal
    tar -xzf "$LATEST_BACKUP/pg_wal.tar.gz" -C /var/lib/postgresql/data/pg_wal
    echo 'WAL extraction complete'
  elif [ -f "$LATEST_BACKUP/pg_wal.tar" ]; then
    echo 'Found pg_wal.tar, extracting WAL...'
    mkdir -p /var/lib/postgresql/data/pg_wal
    tar -xf "$LATEST_BACKUP/pg_wal.tar" -C /var/lib/postgresql/data/pg_wal
    echo 'WAL extraction complete'
  else
    echo 'No pg_wal tar found — continuing without archived WAL files.'
  fi

  # Verify extraction worked
  if [ -f /var/lib/postgresql/data/PG_VERSION ]; then
    echo "PostgreSQL data directory successfully created"
    PG_VERSION=$(cat /var/lib/postgresql/data/PG_VERSION)
    echo "PostgreSQL version: $PG_VERSION"
  else
    echo "ERROR: PG_VERSION not found after extraction!"
    echo "Contents of data directory:"
    ls -la /var/lib/postgresql/data/
    exit 1
  fi

  # Create standby.signal
  echo 'Creating standby.signal...'
  touch /var/lib/postgresql/data/standby.signal
  echo 'standby.signal created'

  # Create postgresql.auto.conf with recovery parameters
  echo 'Writing postgresql.auto.conf with recovery parameters...'
  echo "primary_conninfo = 'host=transactional_db port=5432 user=replicator password=replicator_password'" > /var/lib/postgresql/data/postgresql.auto.conf
  echo "restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'" >> /var/lib/postgresql/data/postgresql.auto.conf
  echo "recovery_target_timeline = 'latest'" >> /var/lib/postgresql/data/postgresql.auto.conf
  echo "hot_standby = on" >> /var/lib/postgresql/data/postgresql.auto.conf

  chown postgres:postgres /var/lib/postgresql/data/postgresql.auto.conf
  chmod 600 /var/lib/postgresql/data/postgresql.auto.conf
  echo 'postgresql.auto.conf created'
  
  echo "Fixing permissions on data directory..."
  chmod -R 700 /var/lib/postgresql/data
  chown -R postgres:postgres /var/lib/postgresql/data
  echo "Permissions fixed"
  echo '=== Standby database initialized successfully ==='
else
  echo 'Data directory already exists (PG_VERSION found), starting standby server...'
fi

echo "=== Initialization script complete, starting PostgreSQL ==="