DROP FUNCTION IF EXISTS insert_data_journey;
DROP FUNCTION IF EXISTS update_or_insert_users;
DROP FUNCTION IF EXISTS get_all_routes_by_user;
DROP FUNCTION IF EXISTS get_route;

CREATE OR REPLACE FUNCTION update_or_insert_users( --0 - конфликт на логинах, 1 - значение вставлено, 2 - значение обновлено
    p_users_id INT,
    p_login TEXT,
    p_password TEXT,
    p_user_name TEXT,
    p_email TEXT,
    p_telegram TEXT
) RETURNS INT AS $$
DECLARE
    returned_value INT;
BEGIN
	BEGIN
	  	IF NOT EXISTS(
			SELECT 1 FROM users WHERE users.users_id=p_users_id
		)
		THEN 
			INSERT INTO users (users_id, login, password, user_name, email, telegram)
			VALUES (p_users_id, p_login, p_password, p_user_name, p_email, p_telegram);
			returned_value = 1;
		ELSE
			UPDATE users SET 
				login = p_login,
				password = p_password,
				user_name = p_user_name,
				email = p_email,
				telegram=p_telegram
			WHERE users_id=p_users_id;
			returned_value=2;
		END IF;
	EXCEPTION
        WHEN unique_violation THEN
			returned_value=0;
	END;
	RETURN returned_value;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF exists insert_data_journey;
CREATE OR REPLACE FUNCTION insert_data_journey( --0 - нет такого пользователя, 1 - значение вставлено, 2 - значение обновлено, 3 - ошибка базы данных
    p_users_id INT,
	
    p_frequency_monitoring INT,
    p_start_time_monitoring TIMESTAMP,
	p_finish_time_monitoring TIMESTAMP,
    p_transfers_are_allowed BOOLEAN,
	
    p_type_of_route_name TEXT,
	
	p_start_city_name TEXT,
	p_start_iata_code TEXT,
	p_finish_city_name TEXT,
	p_finish_iata_code TEXT,
	
	p_time_of_checking TIMESTAMP,
	p_ticket_data JSON,
	p_route_monitoring_id INT DEFAULT NULL
)RETURNS TABLE(returning_route_monitoring_id INT, status INT) AS $$
DECLARE
    v_type_of_route_id INT;
	v_start_location_id INT;
	v_finish_location_id INT;
	v_route_id INT;
	v_route_monitoring_id INT;
BEGIN
	IF NOT EXISTS(
		SELECT * FROM users WHERE users_id=p_users_id
	)THEN
		returning_route_monitoring_id:=NULL;
		status:=0;
		RETURN NEXT;
		RETURN;
	END IF;
	BEGIN
		SELECT type_of_route_id INTO v_type_of_route_id FROM type_of_route WHERE type_name = p_type_of_route_name;
		IF v_type_of_route_id IS NULL THEN
			INSERT INTO type_of_route(type_name)
			VALUES (p_type_of_route_name)
			RETURNING type_of_route_id INTO v_type_of_route_id;
		END IF;
	
		SELECT location_id INTO v_start_location_id FROM location 
		WHERE city_name = p_start_city_name AND IATA_code = p_start_iata_code;
		IF v_start_location_id IS NULL THEN
			INSERT INTO location(city_name,IATA_code)
			VALUES (p_start_city_name,p_start_iata_code)
			RETURNING location_id INTO v_start_location_id;
		END IF;
	
		SELECT location_id INTO v_finish_location_id FROM location 
		WHERE city_name = p_finish_city_name AND IATA_code = p_finish_iata_code;
		IF v_finish_location_id IS NULL THEN
			INSERT INTO location(city_name,IATA_code)
			VALUES (p_finish_city_name,p_finish_iata_code)
			RETURNING location_id INTO v_finish_location_id;
		END IF;
	
		SELECT route_id INTO v_route_id FROM route 
		WHERE type_of_route_id = v_type_of_route_id
		AND start_location_id = v_start_location_id AND finish_location_id = v_finish_location_id;
		IF v_route_id IS NULL THEN
			INSERT INTO route(type_of_route_id,start_location_id,finish_location_id)
			VALUES (v_type_of_route_id,v_start_location_id,v_finish_location_id)
			RETURNING route_id INTO v_route_id;
		END IF;

		IF p_route_monitoring_id IS NULL 
		THEN
			INSERT INTO route_monitoring(
				users_id,
				route_id,
				frequency_monitoring,
				start_time_monitoring,
				finish_time_monitoring,
				transfers_are_allowed)
			VALUES(
				p_users_id,
				v_route_id,
				p_frequency_monitoring,
				p_start_time_monitoring,
				p_finish_time_monitoring,
				p_transfers_are_allowed)
			RETURNING route_monitoring_id INTO v_route_monitoring_id;
			returning_route_monitoring_id:=v_route_monitoring_id;
			status:=1;
		ELSIF NOT EXISTS (SELECT * FROM route_monitoring WHERE route_monitoring_id = p_route_monitoring_id) THEN
			INSERT INTO route_monitoring(
				route_monitoring_id,
				users_id,
				route_id,
				frequency_monitoring,
				start_time_monitoring,
				finish_time_monitoring,
				transfers_are_allowed)
			VALUES(
				p_route_monitoring_id,
				p_users_id,
				v_route_id,
				p_frequency_monitoring,
				p_start_time_monitoring,
				p_finish_time_monitoring,
				p_transfers_are_allowed)
			RETURNING route_monitoring_id INTO v_route_monitoring_id;
			returning_route_monitoring_id:=v_route_monitoring_id;
			status:=1;
		ELSE
			UPDATE 
				route_monitoring
			SET 
				route_id = v_route_id,
				frequency_monitoring = p_frequency_monitoring,
				start_time_monitoring = p_start_time_monitoring,
				finish_time_monitoring = p_finish_time_monitoring,
				transfers_are_allowed = p_transfers_are_allowed
			WHERE route_monitoring_id = p_route_monitoring_id;
			returning_route_monitoring_id:=p_route_monitoring_id;
			status:=2;
			v_route_monitoring_id:=p_route_monitoring_id;
		END IF;
		
		INSERT INTO ticket_data(route_monitoring_id,time_of_checking,ticket_data)
		VALUES (v_route_monitoring_id,p_time_of_checking, p_ticket_data);
		
		RETURN NEXT;
		RETURN;
	EXCEPTION
    	WHEN OTHERS THEN
			returning_route_monitoring_id:=NULL;
			status:=3;
			RETURN NEXT;
			RETURN;
	END;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_all_routes_by_user;
CREATE OR REPLACE FUNCTION get_all_routes_by_user(
    p_user_id INT
)
RETURNS TABLE(
    route_monitoring_id INT,
    frequency_monitoring INT,
    start_time_monitoring TIMESTAMP,
    finish_time_monitoring TIMESTAMP,
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
        ls.city_name::text AS start_city,
        ls.IATA_code::text AS start_iata,
        lf.city_name::text AS finish_city,
        lf.IATA_code::text AS finish_iata
    FROM route_monitoring rm
    JOIN route r ON rm.route_id = r.route_id 
    JOIN "location" ls ON r.start_location_id = ls.location_id
    JOIN "location" lf ON r.finish_location_id = lf.location_id 
    WHERE rm.users_id = p_user_id;
END;
$$;

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

