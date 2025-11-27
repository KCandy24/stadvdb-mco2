CREATE SCHEMA IF NOT EXISTS analytical;

DROP TABLE IF EXISTS analytical.etl_log;

CREATE TABLE analytical.etl_log (
    log_id SERIAL PRIMARY KEY,
    last_run_time TIMESTAMP DEFAULT '1900-01-01 00:00:00',
    status VARCHAR(20) DEFAULT 'PENDING'
);

INSERT INTO analytical.etl_log (last_run_time, status) 
SELECT '1900-01-01 00:00:00', 'INIT'
WHERE NOT EXISTS (SELECT 1 FROM analytical.etl_log);

CREATE TABLE IF NOT EXISTS analytical.dim_customer(
    customer_id SERIAL PRIMARY KEY,
    o_user_id INT,
    lastname VARCHAR(50),
    firstname VARCHAR(50),
    birthday TIMESTAMP,
    email VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS analytical.dim_show(
    show_id SERIAL PRIMARY KEY,
    o_play_id INT,
    o_showing_id INT,
    o_run_id INT,
    run_start_ts TIMESTAMP, 
    basefee NUMERIC(10,2),
    play_name VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS analytical.dim_venue(
    venue_id SERIAL PRIMARY KEY,
    o_theater_id INT,
    o_seat_id INT,
    theater_name VARCHAR(50),
    location VARCHAR(50),
    seat_column INT,
    seat_row INT
);

CREATE TABLE IF NOT EXISTS analytical.dim_time (
    time_id SERIAL PRIMARY KEY,
    sale_date DATE,
    day_number INT,
    month_number INT,
    quarter INT,
    year INT
);

CREATE TABLE IF NOT EXISTS analytical.fact_sale (
    sale_id SERIAL PRIMARY KEY,
    customer_id INT,
    venue_id INT, 
    show_id INT,
    time_id INT,
    ticket_price NUMERIC(10,2),
    o_reservation_id INT,
    
    CONSTRAINT fk_show
        FOREIGN KEY(show_id)
        REFERENCES analytical.dim_show(show_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_customer
        FOREIGN KEY(customer_id)
        REFERENCES analytical.dim_customer(customer_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_venue
        FOREIGN KEY(venue_id)
        REFERENCES analytical.dim_venue(venue_id)
        ON DELETE SET NULL,
        
    CONSTRAINT fk_time
        FOREIGN KEY(time_id)
        REFERENCES analytical.dim_time(time_id)
        ON DELETE SET NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_show_run_oid ON analytical.dim_show(o_run_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_customer_oid ON analytical.dim_customer(o_user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_venue_oid ON analytical.dim_venue(o_seat_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_time_date ON analytical.dim_time(sale_date);
CREATE UNIQUE INDEX IF NOT EXISTS idx_fact_sale_oid ON analytical.fact_sale(o_reservation_id);

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS transactional_server CASCADE;

CREATE SERVER transactional_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'transactional_db', port '5432', dbname 'appdb_transactional');

CREATE USER MAPPING FOR postgres
    SERVER transactional_server
    OPTIONS (user 'postgres', password 'postgres');

CREATE SCHEMA IF NOT EXISTS source_transactional;

IMPORT FOREIGN SCHEMA transactional
    FROM SERVER transactional_server
    INTO source_transactional;