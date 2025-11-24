CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator_password';

GRANT CONNECT ON DATABASE appdb_transactional TO replicator;

COPY (SELECT 'host replication replicator all md5') TO PROGRAM 'echo "host replication replicator all md5" >> /var/lib/postgresql/data/pg_hba.conf';

SELECT pg_reload_conf();