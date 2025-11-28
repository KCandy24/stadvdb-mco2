#!/bin/bash

echo "=== Failover Monitor Starting ==="
echo "Primary host: ${PRIMARY_HOST}"
echo "Standby host: ${STANDBY_HOST}"
echo "Check interval: ${CHECK_INTERVAL}s"
echo "Failure threshold: ${FAILURE_THRESHOLD}s"

CONSECUTIVE_FAILURES=0
FAILURE_START_TIME=0
PROMOTED=false

while true; do
  # Check if primary is accessible
  if pg_isready -h "$PRIMARY_HOST" -U postgres -d appdb_transactional > /dev/null 2>&1; then
    if [ $CONSECUTIVE_FAILURES -gt 0 ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Primary recovered after $CONSECUTIVE_FAILURES failed checks"
    fi
    CONSECUTIVE_FAILURES=0
    FAILURE_START_TIME=0
  else
    CURRENT_TIME=$(date +%s)
    
    if [ $CONSECUTIVE_FAILURES -eq 0 ]; then
      FAILURE_START_TIME=$CURRENT_TIME
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Primary database is not responding - starting failure timer"
    fi
    
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    TIME_DOWN=$((CURRENT_TIME - FAILURE_START_TIME))
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Primary down for ${TIME_DOWN}s (${CONSECUTIVE_FAILURES} consecutive failures)"
    
    # Check if we've exceeded the threshold
    if [ $TIME_DOWN -ge $FAILURE_THRESHOLD ] && [ "$PROMOTED" = false ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL: Primary has been down for ${TIME_DOWN}s - initiating failover!"
      
      # Promote standby by connecting to it via psql and executing pg_promote
      echo "Promoting standby database..."
      # Connection will be terminated during promotion - this is expected
      PGPASSWORD=postgres psql -h "$STANDBY_HOST" -U postgres -d postgres -c "SELECT pg_promote();" 2>&1 | grep -v "server closed the connection" | grep -v "connection to server was lost" | grep -v "terminated abnormally" | grep -v "terminating connection"
      
      # Wait for standby to finish promotion and come back online
      echo "Waiting for promoted standby to become available..."
      sleep 5
      
      # Verify promotion was successful by checking if it's now a primary
      for i in {1..10}; do
        if pg_isready -h "$STANDBY_HOST" -U postgres -d postgres > /dev/null 2>&1; then
          # Check if it's in recovery mode (standby) or not (primary)
          IS_IN_RECOVERY=$(PGPASSWORD=postgres psql -h "$STANDBY_HOST" -U postgres -d postgres -t -c "SELECT pg_is_in_recovery();" 2>/dev/null | tr -d ' ')
          
          if [ "$IS_IN_RECOVERY" = "f" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Standby promoted to primary!"
            PROMOTED=true
            echo "FAILOVER COMPLETED - Manual intervention required to rebuild replication"
            break
          fi
        fi
        echo "Waiting for promotion to complete (attempt $i/10)..."
        sleep 2
      done
      
      if [ "$PROMOTED" = false ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to verify standby promotion!"
      fi
    fi
  fi
  
  sleep "$CHECK_INTERVAL"
done