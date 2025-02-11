ALTER TABLE users
DROP CONSTRAINT  IF EXISTS unique_login1;

DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS route_monitoring CASCADE;
DROP TABLE IF EXISTS ticket_data CASCADE;
DROP TABLE IF EXISTS route CASCADE;
DROP TABLE IF EXISTS location CASCADE;
DROP TABLE IF EXISTS type_of_route CASCADE;

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
	users_id INT,
	route_id INT,
	frequency_monitoring INT, -- интервал будет записываться в часах
	start_time_monitoring TIMESTAMP,
	finish_time_monitoring TIMESTAMP,
	transfers_are_allowed BOOLEAN
);

CREATE TABLE ticket_data(
	ticket_data_id SERIAL PRIMARY KEY,
	route_monitoring_id INT,
	time_of_checking TIMESTAMP,
	price INT,
	ticket_data JSON
);

CREATE TABLE route(
	route_id SERIAL PRIMARY KEY,
	type_of_route_id INT,
	start_location_id INT,
	finish_location_id INT
);


CREATE TABLE location(
	location_id SERIAL PRIMARY KEY,
	city_name varchar(50),
	IATA_code varchar(50)
);

CREATE TABLE type_of_route(
	type_of_route_id SERIAL PRIMARY KEY,
	type_name varchar(50)
);



ALTER TABLE route_monitoring
    ADD FOREIGN KEY (users_id) REFERENCES users(users_id)
		ON UPDATE CASCADE ON DELETE CASCADE,
    ADD FOREIGN KEY (route_id) REFERENCES route(route_id)
		ON UPDATE CASCADE ON DELETE CASCADE;
		
ALTER TABLE route
    ADD FOREIGN KEY (type_of_route_id) REFERENCES type_of_route(type_of_route_id)
		ON UPDATE CASCADE ON DELETE CASCADE,
    ADD FOREIGN KEY (start_location_id) REFERENCES location(location_id)
		ON UPDATE CASCADE ON DELETE CASCADE,
    ADD FOREIGN KEY (finish_location_id) REFERENCES location(location_id)
		ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ticket_data
    ADD FOREIGN KEY (route_monitoring_id) REFERENCES route_monitoring(route_monitoring_id)
		ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE users
ADD CONSTRAINT unique_login1 UNIQUE (login);



CREATE INDEX users___users_id_idx ON users(users_id);

CREATE INDEX route_monitoring___route_monitoring_id_idx ON route_monitoring (route_monitoring_id);
CREATE INDEX route_monitoring___users_id_idx ON route_monitoring (users_id);
CREATE INDEX route_monitoring___route_id_idx ON route_monitoring (route_id);


CREATE INDEX ticket_data___ticket_data_id_idx ON ticket_data(ticket_data_id);
CREATE INDEX ticket_data___time_of_checking_idx ON ticket_data(time_of_checking);

CREATE INDEX route___route_id_idx ON route(route_id);
CREATE INDEX route___start_location_id_idx ON route(start_location_id);
CREATE INDEX route___finish_location_id_idx ON route(finish_location_id);

CREATE INDEX location___location_id_idx ON location(location_id);

