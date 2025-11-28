DROP PROCEDURE IF EXISTS transactional.batch_create_reservation;
DROP FUNCTION IF EXISTS transactional.read_reservations_of_user (integer);

DROP FUNCTION IF EXISTS transactional.seats_taken_for_run(integer, integer[]);

-- ! DON'T TOUCH - Roemer
CREATE OR REPLACE PROCEDURE transactional.batch_create_reservation(
    p_user_id INT,
    p_run_id INT,
    p_seat_ids INT[]
)
AS $$
BEGIN
    INSERT INTO transactional.reservation (user_id, run_id, seat_id)
    SELECT
        p_user_id,
        p_run_id,
        s
    FROM unnest(p_seat_ids) AS s
    ORDER BY s ASC;
END;
$$ LANGUAGE plpgsql;
-- ! End of DON'T TOUCH

CREATE OR REPLACE FUNCTION transactional.read_reservations_of_user (p_user_id integer)
RETURNS TABLE (
    reservation_id int,
    play_name varchar(50),
    theater_name varchar(50),
    seat int,
    period_start timestamp,
    period_end timestamp
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.reservation_id,
        p.play_name,
        t.theater_name,
        r.seat_id,
        s.reservation_period_start,
        s.reservation_period_end
    FROM transactional.reservation r
    JOIN transactional.run ru ON r.run_id = ru.run_id
    JOIN transactional.showing s ON ru.showing_id = s.showing_id
    JOIN transactional.play p ON s.play_id = p.play_id
    JOIN transactional.theater t ON s.theater_id = t.theater_id
    WHERE r.user_id = p_user_id
    ORDER BY r.seat_id;
END;
$$;


CREATE OR REPLACE FUNCTION transactional.seats_taken_for_run(
    p_run_id integer,
    p_seat_ids integer[]
)
RETURNS TABLE (
    seat_id integer,
    taken boolean
)
LANGUAGE sql
AS $$
    SELECT s AS seat_id,
           EXISTS (
             SELECT 1
             FROM transactional.reservation r
             WHERE r.run_id = p_run_id AND r.seat_id = s
           ) AS taken
    FROM unnest(p_seat_ids) AS s;
$$;
