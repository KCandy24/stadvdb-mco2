-- Run
DROP PROCEDURE IF EXISTS transactional.create_run(integer, timestamp, timestamp);
DROP FUNCTION IF EXISTS transactional.read_run(integer);
DROP FUNCTION IF EXISTS transactional.read_runs_by_showing(integer);
DROP PROCEDURE IF EXISTS transactional.update_run(integer, timestamp, timestamp);
DROP PROCEDURE IF EXISTS transactional.delete_run_by_id(integer);

CREATE OR REPLACE PROCEDURE transactional.create_run(in_showing_id integer, in_run_start timestamp, in_run_end timestamp)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO transactional.run (showing_id, run_start_time, run_end_time)
    VALUES (in_showing_id, in_run_start, in_run_end);
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_run(in_run_id integer)
RETURNS SETOF transactional.run
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.run WHERE run_id = in_run_id;
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_runs_by_showing(in_showing_id integer)
RETURNS SETOF transactional.run
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.run WHERE showing_id = in_showing_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.update_run(in_run_id integer, in_run_start timestamp, in_run_end timestamp)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactional.run
    SET run_start_time = COALESCE(in_run_start, run_start_time),
        run_end_time = COALESCE(in_run_end, run_end_time)
    WHERE run_id = in_run_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_run_by_id(in_run_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.run WHERE run_id = in_run_id;
END;
$$;