DROP PROCEDURE IF EXISTS transactional.batch_create_seat;

CREATE OR REPLACE PROCEDURE transactional.batch_create_seat(
    p_theater_id integer,
    p_rows integer,
    p_columns integer,
    p_default_price numeric(10, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_rows IS NULL OR p_columns IS NULL OR p_rows < 1 OR p_columns < 1 THEN
        RAISE EXCEPTION 'rows and columns must be positive integers';
    END IF;

    INSERT INTO transactional.seat (theater_id, seat_row, seat_column, pricing)
    SELECT
        p_theater_id,
        r,
        c,
        p_default_price
    FROM generate_series(1, p_rows) AS r
    CROSS JOIN generate_series(1, p_columns) AS c;
END;
$$;