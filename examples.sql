SELECT * FROM
insert_data_journey(
    2,                                      -- p_users_id
    15,                                     -- p_frequency_monitoring
    '2025-01-01 10:00:00'::timestamp,       -- p_start_time_monitoring
    '2025-01-01 12:00:00'::timestamp,       -- p_finish_time_monitoring
    TRUE,                                   -- p_transfers_are_allowed
    'Route A',                              -- p_type_of_route_name
    'New York',                              -- p_start_city_name
    'JFK',                                   -- p_start_iata_code
    'Los Angeles',                          -- p_finish_city_name
    'LAX',                                   -- p_finish_iata_code
    '2025-01-01 09:00:00'::timestamp,       -- p_time_of_checking
    '{"ticket_type": "economy", "price": 199.99}'::json  -- p_ticket_data
);

SELECT * FROM users;
SELECT * FROM route_monitoring;
SELECT * FROM route;
SELECT * FROM location;
SELECT * FROM type_of_route;
SELECT * FROM ticket_data;




DROP FUNCTION IF EXISTS get_route;
CREATE OR REPLACE FUNCTION get_route(
    p_user_id INT,
	p_route_monitoring_id INT
)
RETURNS TABLE(
    route_monitoring_id INT,
    frequency_monitoring INT,
    start_time_monitoring TIMESTAMP,
    finish_time_monitoring TIMESTAMP,
    transfers_are_allowed BOOLEAN,
    start_city TEXT,
    start_iata TEXT,
    finish_city TEXT,
    finish_iata TEXT
) 
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rm.route_monitoring_id,
        rm.frequency_monitoring,
        rm.start_time_monitoring,
        rm.finish_time_monitoring,
	rm.transfers_are_allowed,
        ls.city_name::text AS start_city,
        ls.IATA_code::text AS start_iata,
        lf.city_name::text AS finish_city,
        lf.IATA_code::text AS finish_iata
    FROM route_monitoring rm
    JOIN route r ON rm.route_id = r.route_id 
    JOIN "location" ls ON r.start_location_id = ls.location_id
    JOIN "location" lf ON r.finish_location_id = lf.location_id 
    WHERE rm.users_id = p_user_id AND rm.route_monitoring_id = p_route_monitoring_id;
END;
$$;
