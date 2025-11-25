-- Showings

DROP PROCEDURE IF EXISTS transactional.create_showing(integer, integer, numeric, timestamp, timestamp);
DROP FUNCTION IF EXISTS transactional.read_showing(integer);
DROP FUNCTION IF EXISTS transactional.read_showings_by_play(integer);
DROP PROCEDURE IF EXISTS transactional.update_showing(integer, numeric, timestamp, timestamp);
DROP PROCEDURE IF EXISTS transactional.delete_showing_by_id(integer);

CREATE OR REPLACE PROCEDURE transactional.create_showing(in_play_id integer, in_theater_id integer, in_basefee numeric, in_res_start timestamp, in_res_end timestamp)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO transactional.showing (play_id, theater_id, basefee, reservation_period_start, reservation_period_end)
    VALUES (in_play_id, in_theater_id, in_basefee, in_res_start, in_res_end);
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_showing(in_showing_id integer)
RETURNS SETOF transactional.showing
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.showing WHERE showing_id = in_showing_id;
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_showings_by_play(in_play_id integer)
RETURNS SETOF transactional.showing
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.showing WHERE play_id = in_play_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.update_showing(in_showing_id integer, in_basefee numeric, in_res_start timestamp, in_res_end timestamp)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactional.showing
    SET basefee = COALESCE(in_basefee, basefee),
        reservation_period_start = COALESCE(in_res_start, reservation_period_start),
        reservation_period_end = COALESCE(in_res_end, reservation_period_end)
    WHERE showing_id = in_showing_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_showing_by_id(in_showing_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.showing WHERE showing_id = in_showing_id;
END;
$$;
