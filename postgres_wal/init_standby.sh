#!/bin/bash
echo "=== Standby Initialization Script Starting ==="

if [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
  echo 'No data directory found, waiting for base backup...'

  # Wait for a backup directory
  while true; do
    BACKUP_DIR=$(ls -d /pg_basebackups/backup_* 2>/dev/null | head -1)
    if [ -n "$BACKUP_DIR" ]; then
      echo "Backup directory found: $BACKUP_DIR"
      break
    else
      echo 'Backup directory NOT found, still waiting...'
      sleep 5
    fi
  done

  LATEST_BACKUP=$(ls -td /pg_basebackups/backup_* | head -1)
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