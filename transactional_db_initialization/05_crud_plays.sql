-- Plays

DROP PROCEDURE IF EXISTS transactional.create_play(varchar);
DROP FUNCTION IF EXISTS transactional.read_play(integer);
DROP FUNCTION IF EXISTS transactional.read_play_by_name(varchar);
DROP PROCEDURE IF EXISTS transactional.update_play(integer, varchar);
DROP PROCEDURE IF EXISTS transactional.delete_play_by_id(integer);
DROP PROCEDURE IF EXISTS transactional.delete_play_by_name(varchar);

CREATE OR REPLACE PROCEDURE transactional.create_play(in_play_name varchar(50))
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO transactional.play (play_name) VALUES (in_play_name);
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_play(in_play_id integer)
RETURNS SETOF transactional.play
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.play WHERE play_id = in_play_id;
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_play_by_name(in_play_name varchar(50))
RETURNS SETOF transactional.play
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.play WHERE play_name = in_play_name;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.update_play(in_play_id integer, in_play_name varchar(50))
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactional.play
    SET play_name = COALESCE(in_play_name, play_name)
    WHERE play_id = in_play_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_play_by_id(in_play_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.play WHERE play_id = in_play_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_play_by_name(in_play_name varchar(50))
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.play WHERE play_name = in_play_name;
END;
$$;
