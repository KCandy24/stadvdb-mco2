CREATE SCHEMA IF NOT EXISTS transactional;

CREATE TYPE reservation_status AS ENUM ('Confirmed', 'Completed', 'Cancelled-User', 'Cancelled-Event');

CREATE TABLE IF NOT EXISTS transactional.user (
    user_id SERIAL PRIMARY KEY,
    lastname VARCHAR(50),
    firstname VARCHAR(50),
    birthday TIMESTAMP,
    email VARCHAR(200) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL  --  needs to be hashed
);

CREATE TABLE IF NOT EXISTS transactional.play(
    play_id SERIAL PRIMARY KEY,
    play_name VARCHAR(50),
    play_duration_min INT
);

CREATE TABLE IF NOT EXISTS transactional.theater(
    theater_id SERIAL PRIMARY KEY,
    theater_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS transactional.showing(
    showing_id SERIAL PRIMARY KEY,
    play_id INT,
    theater_id INT,
    basefee NUMERIC(10, 2),
    reservation_period_start TIMESTAMP,
    reservation_period_end TIMESTAMP,
    
    CONSTRAINT fk_play
        FOREIGN KEY(play_id)
        REFERENCES transactional.play(play_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_theater
        FOREIGN KEY(theater_id)
        REFERENCES transactional.theater(theater_id)
        ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS transactional.seat(
    seat_id SERIAL PRIMARY KEY,
    theater_id INT,
    seat_row INT NOT NULL,
    seat_column INT NOT NULL,
    pricing NUMERIC(10, 2), 

    CONSTRAINT fk_theater
        FOREIGN KEY(theater_id)
        REFERENCES transactional.theater(theater_id)
        ON DELETE CASCADE,

    UNIQUE(theater_id, seat_row, seat_column)
);

CREATE TABLE IF NOT EXISTS transactional.reservation (
    reservation_id SERIAL PRIMARY KEY,
    user_id INT,
    seat_id INT,
    showing_id INT,
    time_reserved TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status reservation_status,

    CONSTRAINT fk_user
        FOREIGN KEY(user_id) 
        REFERENCES transactional.user(user_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_showing
        FOREIGN KEY(showing_id)
        REFERENCES transactional.showing(showing_id)
        ON DELETE SET NULL,
        
    CONSTRAINT fk_seat
        FOREIGN KEY(seat_id)
        REFERENCES transactional.seat(seat_id)
        ON DELETE SET NULL,
        
    UNIQUE(seat_id, showing_id)
);