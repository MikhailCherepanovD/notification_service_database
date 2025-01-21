DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS route_monitoring CASCADE ;
DROP TABLE IF EXISTS users_route_monitoring CASCADE;
DROP FUNCTION IF exists update_or_insert_users;


CREATE TABLE users(
	users_id SERIAL PRIMARY KEY,
	login varchar(50),
	password varchar(100),
	user_name varchar(50),
	email varchar(50),
	telegram varchar(50)
);

CREATE TABLE route_monitoring(
	route_monitoring_id SERIAL PRIMARY KEY,
	type_of_route varchar(50),
	start_point varchar(50),
	finish_point varchar(50),
	start_time_monitoring varchar(50),
	finish_time_monitoring varchar(50)
);

CREATE TABLE users_route_monitoring(
    users_id INT,
    route_monitoring_id INT,
	PRIMARY KEY (users_id, route_monitoring_id)
);

ALTER TABLE users
ADD CONSTRAINT unique_login1 UNIQUE (login);


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
