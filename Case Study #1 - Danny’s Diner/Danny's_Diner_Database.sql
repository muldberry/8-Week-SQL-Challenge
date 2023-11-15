-- Create Database
CREATE DATABASE diner;

-- Use Database
USE diner;

-- Create Menu Table
CREATE TABLE menu(
	product_id INTEGER NOT NULL AUTO_INCREMENT,
	product_name VARCHAR(5),
	price INTEGER,
    PRIMARY KEY (product_id)
);

INSERT INTO menu
	(product_name, price)
VALUES
	('sushi', 10),
    ('curry', 15),
    ('ramen', 12);

-- Create Sales Table
CREATE TABLE sales(
	customer_id VARCHAR(1) NOT NULL,
	order_date DATE,
	product_id INTEGER,
    FOREIGN KEY (product_id) REFERENCES menu(product_id)
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2023-01-01', 1),
	('A', '2023-01-01', 2),
	('A', '2023-01-07', 2),
	('A', '2023-01-10', 3),
	('A', '2023-01-11', 3),
	('A', '2023-01-11', 3),
	('B', '2023-01-01', 2),
	('B', '2023-01-02', 2),
	('B', '2023-01-04', 1),
	('B', '2023-01-11', 1),
	('B', '2023-01-16', 3),
	('B', '2023-02-01', 3),
	('C', '2023-01-01', 3),
	('C', '2023-01-01', 3),
	('C', '2023-01-07', 3);

-- Create Members Table
CREATE TABLE members(
	customer_id VARCHAR(1) NOT NULL,
    join_date DATE,
    PRIMARY KEY (customer_id)
);

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');
