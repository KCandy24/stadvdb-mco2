TRUNCATE TABLE transactional.users RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.play RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.theater RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.seat RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.showing RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.run RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.reservation RESTART IDENTITY CASCADE;

-- USER

INSERT INTO transactional.users (lastname, firstname, birthday, email, password)
VALUES 
('admin', 'admin', '1970-01-01', 'admin@admin.com', 'admin'),
('Doe', 'John', '1985-04-12', 'john.doe@example.com', 'password'),
('Smith', 'Jane', '1992-08-23', 'jane.smith@test.co', 'password'),
('Garcia', 'Carlos', '1978-11-05', 'carlos.garcia@mail.net', 'password'),
('Chen', 'Wei', '1995-02-14', 'wei.chen88@tech.org', 'password'),
('Johnson', 'Emily', '1989-12-30', 'emily.j@webmail.com', 'password'),
('Nkosi', 'Thabo', '1990-06-18', 'thabo.nkosi@africa.za', 'password'),
('Ivanov', 'Dmitry', '1983-09-25', 'd.ivanov@post.ru', 'password'),
('Dubois', 'Marie', '1998-03-10', 'marie.dubois@paris.fr', 'password'),
('Tanaka', 'Kenji', '1975-07-07', 'kenji.t@nippon.jp', 'password'),
('Silva', 'Ana', '2001-01-15', 'ana.silva@br-mail.com', 'password'),
('Kim', 'Min-ji', '1996-05-21', 'minji.kim@seoul.kr', 'password'),
('Muller', 'Hans', '1980-02-14', 'hans.muller@berlin.de', 'password'),
('Rossi', 'Giulia', '1993-11-09', 'g.rossi@milano.it', 'password'),
('Santos', 'Maria', '1988-07-30', 'maria.santos@lisboa.pt', 'password'),
('Popov', 'Alexei', '1991-04-05', 'alexei.popov@moscow.ru', 'password'),
('Oconnell', 'Liam', '1994-09-12', 'liam.oconnell@dublin.ie', 'password'),
('Andersson', 'Sven', '1982-12-01', 'sven.andersson@stockholm.se', 'password'),
('Wang', 'Li', '1997-08-19', 'wang.li@beijing.cn', 'password'),
('Kowalski', 'Jakub', '1986-03-27', 'j.kowalski@warsaw.pl', 'password'),
('Papadopoulos', 'Nikos', '1990-10-15', 'n.papadopoulos@athens.gr', 'password'),
('Jensen', 'Lars', '1979-06-22', 'lars.jensen@copenhagen.dk', 'password'),
('Singh', 'Aarav', '1995-01-08', 'aarav.singh@delhi.in', 'password'),
('Bernard', 'Lucas', '1987-05-14', 'lucas.bernard@lyon.fr', 'password'),
('Ahmed', 'Omar', '1992-09-03', 'omar.ahmed@cairo.eg', 'password'),
('Yamamoto', 'Yuki', '1999-02-28', 'yuki.yamamoto@tokyo.jp', 'password');

-- PLAYS

INSERT INTO transactional.play (play_name) VALUES 
    ('Hamilton'),
    ('The Lion King'),
    ('Wicked'),
    ('The Phantom of the Opera'),
    ('Tic-Tac-Toe'),
    ('Shrek The Musical'),
    ('Patintero sa Ayala Avenue'),
    ('Alice in Wonderland');

-- THEATER AND SEATS

TRUNCATE TABLE transactional.theater RESTART IDENTITY CASCADE;
TRUNCATE TABLE transactional.seat RESTART IDENTITY CASCADE;

DO $$
DECLARE
    s_theater_id INT;
    s_seat_row INT;
    s_seat_col INT;
    s_price NUMERIC(10,2);
BEGIN
    INSERT INTO transactional.theater (theater_name, location)
    VALUES ('DLSU Ampitheatre', '2401 Taft Ave, Malate, Manila, 1004 Metro Manila')
    RETURNING theater_id INTO s_theater_id;
    FOR s_seat_row IN 1..25 LOOP
        FOR s_seat_col IN 1..30 LOOP
        
            IF s_seat_row <= 5 THEN
                s_price := 200.00;
            ELSIF s_seat_row <= 15 THEN
                s_price := 150.00;
            ELSE
                s_price := 100.00;
            END IF;
            
            INSERT INTO transactional.seat (theater_id, seat_row, seat_column, pricing)
            VALUES (s_theater_id, s_seat_row, s_seat_col, s_price);
        END LOOP;
    END LOOP;

    INSERT INTO transactional.theater (theater_name, location)
    VALUES ('New Frontier Theater', 'Cubao, Quezon City, Metro Manila')
    RETURNING theater_id INTO s_theater_id;

    FOR s_seat_row IN 1..10 LOOP
        FOR s_seat_col IN 1..15 LOOP
            
            IF s_seat_row <= 3 THEN
                s_price := 120.00;
            ELSE
                s_price := 90.00;
            END IF;
            
            INSERT INTO transactional.seat (theater_id, seat_row, seat_column, pricing)
            VALUES (s_theater_id, s_seat_row, s_seat_col, s_price);
        END LOOP;
    END LOOP;

    INSERT INTO transactional.theater (theater_name, location)
    VALUES ('Manila Metropolitan Theater', 'Arroceros Street, Ermita, Manila, Philippines')
    RETURNING theater_id INTO s_theater_id;

    FOR s_seat_row IN 1..15 LOOP
        FOR s_seat_col IN 1..25 LOOP
            
            IF s_seat_row <= 5 THEN
                s_price := 100.00;
            ELSE
                s_price := 50.00;
            END IF;
            
            INSERT INTO transactional.seat (theater_id, seat_row, seat_column, pricing)
            VALUES (s_theater_id, s_seat_row, s_seat_col, s_price);
        END LOOP;
    END LOOP;

END $$;

-- SHOWING AND RUN

DO $$
DECLARE
    s_play_id INT;
    s_theater_id INT;
    s_showing_id INT;
BEGIN

    SELECT play_id INTO s_play_id FROM transactional.play WHERE play_name = 'Patintero sa Ayala Avenue';
    SELECT theater_id INTO s_theater_id FROM transactional.theater WHERE theater_name = 'New Frontier Theater';

    INSERT INTO transactional.showing (play_id, theater_id, basefee, reservation_period_start, reservation_period_end)
    VALUES (s_play_id, s_theater_id, 150.00, '2025-11-23 19:25:00', '2025-12-23 19:25:00')
    RETURNING showing_id INTO s_showing_id;

    INSERT INTO transactional.run (showing_id, run_start_time, run_end_time)
        VALUES 
        (s_showing_id, '2025-12-30 15:25:00', '2025-12-30 17:25:00'),
        (s_showing_id,'2025-12-30 17:30:00','2025-12-30 19:30:00');
    
    SELECT play_id INTO s_play_id FROM transactional.play WHERE play_name = 'Alice in Wonderland';
    SELECT theater_id INTO s_theater_id FROM transactional.theater WHERE theater_name = 'Manila Metropolitan Theater';

    INSERT INTO transactional.showing (play_id, theater_id, basefee, reservation_period_start, reservation_period_end)
    VALUES (s_play_id, s_theater_id, 400.00, '2025-11-20 19:25:00', '2025-12-30 19:25:00')
    RETURNING showing_id INTO s_showing_id;

    INSERT INTO transactional.run (showing_id, run_start_time, run_end_time)
        VALUES 
        (s_showing_id,'2026-1-3 19:25:00','2026-1-3 21:25:00'),
        (s_showing_id,'2026-1-5 19:25:00','2026-1-5 21:25:00'),
        (s_showing_id,'2026-1-7 19:25:00','2026-1-7 21:25:00');

    SELECT play_id INTO s_play_id FROM transactional.play WHERE play_name = 'The Lion King';
    SELECT theater_id INTO s_theater_id FROM transactional.theater WHERE theater_name = 'DLSU Ampitheatre';

    INSERT INTO transactional.showing (play_id, theater_id, basefee, reservation_period_start, reservation_period_end)
    VALUES (s_play_id, s_theater_id, 200.00, '2025-10-20 19:25:00', '2025-10-30 19:25:00')
    RETURNING showing_id INTO s_showing_id;

    INSERT INTO transactional.run (showing_id, run_start_time, run_end_time)
        VALUES 
        (s_showing_id,'2025-11-1 17:30:00','2025-1-1 19:30:00'),
        (s_showing_id,'2025-11-2 17:30:00','2025-1-2 19:30:00'),
        (s_showing_id,'2025-11-3 17:30:00','2025-1-3 19:30:00');
END $$;

-- RESERVATIONS

DO $$
DECLARE
    s_user_id INT;
    s_run_id INT;
    s_seat_id INT;
    s_theater_id INT;
    s_period_start TIMESTAMP;
    s_period_end TIMESTAMP;
    s_random_time TIMESTAMP;
BEGIN
    FOR i IN 1..50 LOOP
    
        SELECT user_id INTO s_user_id 
        FROM transactional.users 
        ORDER BY random() 
        LIMIT 1;

        SELECT 
            r.run_id, 
            s.theater_id, 
            s.reservation_period_start, 
            s.reservation_period_end
        INTO 
            s_run_id, 
            s_theater_id, 
            s_period_start, 
            s_period_end
        FROM transactional.run r
        JOIN transactional.showing s ON r.showing_id = s.showing_id
        ORDER BY random() 
        LIMIT 1;   

        SELECT seat_id INTO s_seat_id 
        FROM transactional.seat 
        WHERE theater_id = s_theater_id 
        ORDER BY random() 
        LIMIT 1;

        s_random_time := s_period_start + random() * (s_period_end - s_period_start);

        INSERT INTO transactional.reservation 
            (user_id, seat_id, run_id, time_reserved)
        VALUES 
            (s_user_id, s_seat_id, s_run_id, s_random_time)
        ON CONFLICT (seat_id, run_id) DO NOTHING;
        
    END LOOP;
END $$;