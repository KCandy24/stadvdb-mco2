-- Theaters

DROP PROCEDURE IF EXISTS transactional.create_theater(varchar, varchar);
DROP FUNCTION IF EXISTS transactional.read_theater(integer);
DROP FUNCTION IF EXISTS transactional.read_theater_by_name(varchar);
DROP PROCEDURE IF EXISTS transactional.update_theater(integer, varchar, varchar);
DROP PROCEDURE IF EXISTS transactional.delete_theater_by_id(integer);
DROP PROCEDURE IF EXISTS transactional.delete_theater_by_name(varchar);

CREATE OR REPLACE PROCEDURE transactional.create_theater(in_theater_name varchar(50), in_location varchar(50))
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO transactional.theater (theater_name, location)
    VALUES (in_theater_name, in_location);
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_theater(in_theater_id integer)
RETURNS SETOF transactional.theater
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM transactional.theater WHERE theater_id = in_theater_id;
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_theater_by_name(in_theater_name varchar(50))
RETURNS SETOF transactional.theater
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM transactional.theater WHERE theater_name = in_theater_name;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.update_theater(in_theater_id integer, in_theater_name varchar(50), in_location varchar(50))
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactional.theater
    SET theater_name = COALESCE(in_theater_name, theater_name),
        location = COALESCE(in_location, location)
    WHERE theater_id = in_theater_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_theater_by_id(in_theater_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.theater WHERE theater_id = in_theater_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_theater_by_name(in_theater_name varchar(50))
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.theater WHERE theater_name = in_theater_name;
END;
$$;
