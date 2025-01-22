ALTER TABLE users
DROP CONSTRAINT unique_login1;

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
	type_of_route_id INT,
	start_point_id INT,
	finish_point_id INT,
	start_time_monitoring varchar(50),
	finish_time_monitoring varchar(50)
);

CREATE TABLE users_route_monitoring(
    users_id INT,
    route_monitoring_id INT,
	PRIMARY KEY (users_id, route_monitoring_id)
);


CREATE TABLE point(
	point_id SERIAL PRIMARY KEY,
	city_name varchar(50),
	IATA_code varchar(5)
);


CREATE TABLE type_of_route(
	type_of_route_id SERIAL PRIMARY KEY,
	type_name varchar(50)
);



ALTER TABLE users_route_monitoring
    ADD FOREIGN KEY (users_id) REFERENCES users(users_id)
		ON UPDATE CASCADE ON DELETE CASCADE,
    ADD FOREIGN KEY (route_monitoring_id) REFERENCES route_monitoring(route_monitoring_id)
		ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE route_monitoring
    ADD FOREIGN KEY (type_of_route_id) REFERENCES type_of_route(type_of_route_id)
		ON UPDATE CASCADE ON DELETE CASCADE,
    ADD FOREIGN KEY (start_point_id) REFERENCES point(point_id)
		ON UPDATE CASCADE ON DELETE CASCADE,
	ADD FOREIGN KEY (finish_point_id) REFERENCES point(point_id)
		ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE users
ADD CONSTRAINT unique_login1 UNIQUE (login);




CREATE INDEX users___users_id_idx ON users(users_id);

CREATE INDEX users_route_monitoring___users_id_idx ON users_route_monitoring (users_id);
CREATE INDEX users_route_monitoring___type_of_route_id_idx ON users_route_monitoring (route_monitoring_id);

CREATE INDEX route_monitoring___route_monitoring_id_idx ON route_monitoring (route_monitoring_id);
CREATE INDEX route_monitoring___type_of_route_id_idx ON route_monitoring (type_of_route_id);
CREATE INDEX route_monitoring___start_point_id_idx ON route_monitoring (start_point_id);
CREATE INDEX route_monitoring___finish_point_id_idx ON route_monitoring (finish_point_id);

CREATE INDEX point___point_id_idx ON point (point_id);

CREATE INDEX type_of_route___type_of_route_id_idx ON type_of_route (type_of_route_id);












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







