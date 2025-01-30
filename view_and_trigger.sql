DROP VIEW IF EXISTS  notification_sending_view;
DROP TABLE IF EXISTS table_route_checking;
DROP TRIGGER IF EXISTS new_route_trigger ON route_monitoring;
DROP FUNCTION IF EXISTS trigger_function;
DROP PROCEDURE IF EXISTS update_time_of_next_checking;

CREATE OR REPLACE VIEW notification_sending_view AS
	SELECT u.users_id, u.user_name, u.telegram, u.email,  rm.route_monitoring_id, rm.frequency_monitoring
	FROM route_monitoring rm 
	JOIN users u ON u.users_id = rm.users_id;
	
	


CREATE TABLE table_route_checking(
	table_route_checking_id SERIAL PRIMARY KEY,
	route_id INT,
	time_of_next_checking TIMESTAMP,
	first_checking BOOLEAN
);



CREATE FUNCTION trigger_function()
RETURNS trigger AS $$
DECLARE
	v_time_of_next_checking TIMESTAMP;
BEGIN 
	IF TG_OP = 'INSERT' THEN
		INSERT INTO table_route_checking(route_id,time_of_next_checking,first_checking)
		VALUES(NEW.route_monitoring_id,CURRENT_TIMESTAMP,True);
		RETURN NEW;
	ELSIF TG_OP = 'DELETE' THEN
		DELETE FROM table_route_checking WHERE route_id = OLD.route_monitoring_id;
		RETURN NULL;
	ELSIF TG_OP = 'UPDATE' THEN
        -- Обновляем информацию о маршруте
        UPDATE table_route_checking
        SET time_of_next_checking = CURRENT_TIMESTAMP
        WHERE route_id = NEW.route_monitoring_id;
        RETURN NEW;  -- Для UPDATE возвращаем NEW
    END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER new_route_trigger AFTER INSERT OR DELETE OR UPDATE ON route_monitoring
	FOR EACH ROW 
	EXECUTE FUNCTION trigger_function();
	
	


CREATE OR REPLACE PROCEDURE update_time_of_next_checking(
	p_route_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
	v_frequency_monitoring INT;
	v_increasing_value INTERVAL;
BEGIN
	SELECT frequency_monitoring
	INTO v_frequency_monitoring
	FROM route_monitoring WHERE route_monitoring_id = p_route_id;
	v_increasing_value:=(v_frequency_monitoring * INTERVAL '1 minute');
	UPDATE table_route_checking SET time_of_next_checking = time_of_next_checking + v_increasing_value WHERE route_id = p_route_id;
END;
$$;

