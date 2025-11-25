# postgres_wal/Dockerfile
FROM postgres:15

RUN mkdir -p /etc/postgresql/conf.d

RUN echo "include_dir = '/etc/postgresql/conf.d'" >> /usr/share/postgresql/postgresql.conf.sample
