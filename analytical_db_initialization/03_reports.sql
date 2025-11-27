CREATE OR REPLACE FUNCTION analytical.box_office_report()
RETURNS TABLE (
    rank BIGINT,
    play_name VARCHAR,
    tickets_sold BIGINT,
    total_revenue NUMERIC,
    avg_ticket_price NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DENSE_RANK() OVER (ORDER BY SUM(fs.ticket_price) DESC) as rank,
        ds.play_name,
        COUNT(fs.sale_id) as tickets_sold,
        SUM(fs.ticket_price) as total_revenue,
        ROUND(AVG(fs.ticket_price), 2) as avg_ticket_price
    FROM analytical.fact_sale fs
    JOIN analytical.dim_show ds ON fs.show_id = ds.show_id
    GROUP BY ds.play_name
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION analytical.high_value_customers()
RETURNS TABLE (
    customer_id INT,
    firstname VARCHAR,
    lastname VARCHAR,
    email VARCHAR,
    tickets_bought BIGINT,
    total_spent NUMERIC,
    spend_difference NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH customer_totals AS (
        SELECT 
            dc.customer_id,
            dc.firstname,
            dc.lastname,
            dc.email,
            COUNT(fs.sale_id) as tickets_bought,
            SUM(fs.ticket_price) as total_spent
        FROM analytical.fact_sale fs
        JOIN analytical.dim_customer dc ON fs.customer_id = dc.customer_id
        GROUP BY dc.customer_id, dc.firstname, dc.lastname, dc.email
    )
    SELECT 
        customer_totals.customer_id,
        customer_totals.firstname,
        customer_totals.lastname,
        customer_totals.email,
        customer_totals.tickets_bought,
        customer_totals.total_spent,
        ROUND(customer_totals.total_spent - (SELECT AVG(ct.total_spent) FROM customer_totals ct), 2)
    FROM 
        customer_totals
    WHERE 
        customer_totals.total_spent > (SELECT AVG(ct.total_spent) FROM customer_totals ct)
    ORDER BY 
        customer_totals.total_spent DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytical.popular_plays_per_theater()
RETURNS TABLE (
    theater_name VARCHAR,
    play_name VARCHAR,
    tickets_sold BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH TheaterSales AS (
        SELECT 
            dv.theater_name,
            ds.play_name,
            COUNT(fs.sale_id) as tickets_sold,
            SUM(fs.ticket_price) as total_revenue
        FROM analytical.fact_sale fs
        JOIN analytical.dim_venue dv ON fs.venue_id = dv.venue_id
        JOIN analytical.dim_show ds ON fs.show_id = ds.show_id
        GROUP BY dv.theater_name, ds.play_name
    ),
    RankedSales AS (
        SELECT 
            ts.theater_name,
            ts.play_name,
            ts.tickets_sold,
            ts.total_revenue,
            RANK() OVER (PARTITION BY ts.theater_name ORDER BY ts.tickets_sold DESC) as popularity_rank
        FROM TheaterSales ts
    )
    SELECT 
        RankedSales.theater_name,
        RankedSales.play_name,
        RankedSales.tickets_sold,
        RankedSales.total_revenue
    FROM RankedSales 
    WHERE RankedSales.popularity_rank = 1;
END;
$$ LANGUAGE plpgsql;