CREATE OR REPLACE FUNCTION transactional.batch_create_reservation(
    p_user_id INT,
    p_run_id INT,
    p_seat_ids INT[]
)
LANGUAGE plpgsql
RETURNS VOID AS $$
BEGIN
    INSERT INTO transactional.reservation (user_id, run_id, seat_id)
    SELECT 
        p_user_id, 
        p_run_id, 
        s 
    FROM unnest(p_seat_ids) AS s
    ORDER BY s ASC;
END;
$$



