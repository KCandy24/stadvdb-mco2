CREATE OR REPLACE PROCEDURE analytical.batch_update_dw_incremental()
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_run TIMESTAMP;
    v_new_run_time TIMESTAMP;
BEGIN
    SELECT last_run_time INTO v_last_run 
    FROM analytical.etl_log 
    ORDER BY log_id DESC LIMIT 1;

    IF v_last_run IS NULL THEN
        v_last_run := '1900-01-01 00:00:00';
    END IF;

    v_new_run_time := NOW();

    RAISE NOTICE 'Starting ETL. Processing data from % to %', v_last_run, v_new_run_time;

    INSERT INTO analytical.dim_customer (o_user_id, lastname, firstname, birthday, email)
    SELECT user_id, lastname, firstname, birthday, email
    FROM source_transactional.users
    ON CONFLICT (o_user_id) DO UPDATE 
    SET lastname = EXCLUDED.lastname, email = EXCLUDED.email;

    INSERT INTO analytical.dim_show (
        o_play_id, o_showing_id, basefee, play_name, o_run_id, run_start_ts
    )
    SELECT 
        p.play_id, s.showing_id, s.basefee, p.play_name, r.run_id, run_start_time
    FROM source_transactional.run r
    JOIN source_transactional.showing s ON r.showing_id = s.showing_id
    JOIN source_transactional.play p ON s.play_id = p.play_id
    ON CONFLICT (o_run_id) DO NOTHING;

    INSERT INTO analytical.dim_venue (o_theater_id, o_seat_id, theater_name, location, seat_column, seat_row)
    SELECT t.theater_id, s.seat_id, t.theater_name, t.location, s.seat_column, s.seat_row
    FROM source_transactional.seat s
    JOIN source_transactional.theater t ON s.theater_id = t.theater_id
    ON CONFLICT (o_seat_id) DO NOTHING;

    INSERT INTO analytical.dim_time (sale_date, day_number, month_number, quarter, year)
    SELECT DISTINCT 
        DATE(r.time_reserved),
        EXTRACT(DAY FROM r.time_reserved),
        EXTRACT(MONTH FROM r.time_reserved),
        EXTRACT(QUARTER FROM r.time_reserved),
        EXTRACT(YEAR FROM r.time_reserved)
    FROM source_transactional.reservation r
    WHERE r.time_reserved > v_last_run 
      AND r.time_reserved <= v_new_run_time
    ON CONFLICT (sale_date) DO NOTHING;

    INSERT INTO analytical.fact_sale (
        customer_id, venue_id, show_id, time_id, 
        ticket_price, o_reservation_id
    )
    SELECT 
        dc.customer_id,
        dv.venue_id,
        ds.show_id,
        dt.time_id,
        (ds.basefee + COALESCE(seat_src.pricing, 0)),
        r.reservation_id
    FROM source_transactional.reservation r
    JOIN source_transactional.run run ON r.run_id = run.run_id
    JOIN source_transactional.showing s ON run.showing_id = s.showing_id
    JOIN source_transactional.seat seat_src ON r.seat_id = seat_src.seat_id

    JOIN analytical.dim_customer dc ON r.user_id = dc.o_user_id
    JOIN analytical.dim_show ds ON run.run_id = ds.o_run_id
    JOIN analytical.dim_venue dv ON r.seat_id = dv.o_seat_id
    JOIN analytical.dim_time dt ON DATE(r.time_reserved) = dt.sale_date

    WHERE r.time_reserved > v_last_run
      AND r.time_reserved <= v_new_run_time
    ON CONFLICT (o_reservation_id) DO NOTHING;


    INSERT INTO analytical.etl_log (last_run_time, status) 
    VALUES (v_new_run_time, 'SUCCESS');

END;
$$;