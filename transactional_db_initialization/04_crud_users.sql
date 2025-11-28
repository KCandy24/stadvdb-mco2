-- Users
DROP PROCEDURE IF EXISTS transactional.create_user(varchar, varchar, date, varchar, varchar);
DROP FUNCTION IF EXISTS transactional.read_user(integer);

DROP FUNCTION IF EXISTS transactional.verify_user(varchar, varchar);

DROP FUNCTION IF EXISTS transactional.read_user_by_email(varchar);
DROP PROCEDURE IF EXISTS transactional.update_user(integer, varchar, varchar, date, varchar, varchar);
DROP PROCEDURE IF EXISTS transactional.delete_user_by_id(integer);
DROP PROCEDURE IF EXISTS transactional.delete_user_by_email(varchar);

CREATE OR REPLACE PROCEDURE transactional.create_user(in_lastname varchar(50), in_firstname varchar(50), in_birthday date, in_email varchar(200), in_password varchar(200))
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO transactional.users (lastname, firstname, birthday, email, password)
    VALUES (in_lastname, in_firstname, in_birthday, in_email, in_password);
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_user(in_user_id integer)
RETURNS SETOF transactional.users
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.users WHERE user_id = in_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION transactional.verify_user(in_email varchar(200), in_password varchar(200))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id integer;
BEGIN
    SELECT user_id
    INTO v_user_id
    FROM transactional.users
    WHERE email = in_email AND password = in_password
    LIMIT 1;

    RETURN v_user_id; -- returns NULL if no match
END;
$$;

CREATE OR REPLACE FUNCTION transactional.read_user_by_email(in_email varchar(200))
RETURNS SETOF transactional.users
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM transactional.users WHERE email = in_email;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.update_user(in_user_id integer, in_lastname varchar(50), in_firstname varchar(50), in_birthday date, in_email varchar(200), in_password varchar(200))
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactional.users
    SET lastname = COALESCE(in_lastname, lastname),
        firstname = COALESCE(in_firstname, firstname),
        birthday = COALESCE(in_birthday, birthday),
        email = COALESCE(in_email, email),
        password = COALESCE(in_password, password)
    WHERE user_id = in_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_user_by_id(in_user_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.users WHERE user_id = in_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE transactional.delete_user_by_email(in_email varchar(200))
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transactional.users WHERE email = in_email;
END;
$$;
