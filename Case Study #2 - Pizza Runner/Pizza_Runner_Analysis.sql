-- Use Database
USE pizza_runner;

-- PIZZA METRICS
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_order
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_order
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS delivered_orders
FROM runner_orders
WHERE pickup_time <> "null"
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(*) AS pizzas_delivered
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
JOIN pizza_names AS pn
ON pn.pizza_id = co.pizza_id
WHERE pickup_time <> "null"
GROUP BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pizza_name, COUNT(*) AS pizzas_ordered
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
JOIN pizza_names AS pn
ON pn.pizza_id = co.pizza_id
GROUP BY co.customer_id, pn.pizza_name;

-- 6. What was the maximun number of pizzas delivered in a single order?
SELECT COUNT(pizza_id) AS pizzas_delivered
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE ro.pickup_time <> "null"
GROUP BY co.order_id
ORDER BY pizzas_delivered DESC
LIMIT 1;

-- 7. For each customer how many delivered pizzas had at least 1 change and how many had no changees?
SELECT co.customer_id,
SUM(CASE
	WHEN
		(co.exclusions IS NOT NULL AND co.exclusions <> "null" AND LENGTH(co.exclusions) > 0) OR
		(co.extras IS NOT NULL AND co.extras <> "null" AND LENGTH(co.extras) > 0) = TRUE
		THEN 1
		ELSE 0
	END) AS changes,
SUM(CASE
		WHEN
		(co.exclusions IS NOT NULL AND co.exclusions <> "null" AND LENGTH(co.exclusions) > 0) OR
		(co.extras IS NOT NULL AND co.extras <> "null" AND LENGTH(co.extras) > 0) = TRUE
		THEN 0
		ELSE 1
	END) AS no_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE ro.pickup_time <> "null"
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT SUM(co.pizza_id) AS pizzas_delivered_with_exclusions_and_extras
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE co.exclusions IS NOT NULL AND co.exclusions <> "null" AND LENGTH(co.exclusions) > 0 
	AND co.extras IS NOT NULL AND co.extras <> "null" AND LENGTH(co.extras) > 0
    AND ro.pickup_time <> "null";

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS hour, SUM(pizza_id) AS pizzas_ordered
FROM customer_orders
GROUP BY 1;

-- 10. What was the total volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS day_of_the_week, SUM(pizza_id) AS pizzas_ordered
FROM customer_orders
GROUP BY 1;

-- RUNNER AND CUSTOMER EXPERIENCE
-- 11. How many runners signed up for each week period? (i.e. week starts 2020-12-28) 
SELECT DATE_SUB(registration_date, INTERVAL DAYOFWEEK(registration_date) -2 DAY) AS week_period, COUNT(runner_id) AS registrations
FROM runners
GROUP BY 1;

-- 12. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id, ROUND(AVG(MINUTE(TIMEDIFF(TIMESTAMP(pickup_time), co.order_time))), 2) AS avg_time_difference_in_minutes
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
WHERE pickup_time <> "null"
GROUP BY runner_id;

-- 13. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH CTE AS (
	SELECT co.order_id, COUNT(co.pizza_id) AS count_of_pizzas, MINUTE(TIMEDIFF(TIMESTAMP(pickup_time), co.order_time)) AS prep_time_in_minutes
	FROM runner_orders AS ro
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id
	JOIN pizza_names AS pz
	ON co.pizza_id = pz.pizza_id
	WHERE pickup_time <> "null"
	GROUP BY 1, 3)
SELECT count_of_pizzas, ROUND(AVG(prep_time_in_minutes), 0) AS avg_prep_time_in_minutes
FROM CTE
GROUP BY 1;

-- 14. What was the average distance travelled for each customer?
SELECT co.customer_id, ROUND(AVG(ro.distance), 2) AS avg_distance
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
WHERE ro.distance <> "null"
GROUP BY 1;

-- 15. What was the difference betwen the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) AS time_difference_in_minutes
FROM runner_orders 
WHERE duration <> "null";

-- 16. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, ROUND(AVG(distance/ duration), 2) AS speed
FROM runner_orders
WHERE duration <> "null" AND distance <> "null"
GROUP BY 1, 2
ORDER BY runner_id, order_id;

-- 17. What is the successful delivery percentage for each runner?
SELECT runner_id,
	ROUND(SUM(CASE
				WHEN pickup_time = "null" THEN 0
				ELSE 1
			  END) / COUNT(order_id), 2) AS successful_rate
FROM runner_orders
GROUP BY runner_id;

-- IGREDIENT OPTIMISATION
-- 18. What are the standard ingredients for each pizza?
SELECT pn.pizza_name, pt.topping_name
FROM pizza_recipes AS pr
JOIN JSON_TABLE(
	REPLACE (json_array(pr.toppings), ',', '","'),
	'$[*]' COLUMNS (toppings VARCHAR(50) path '$')
) j
JOIN pizza_toppings AS pt
ON j.toppings = pt.topping_id
JOIN pizza_names AS pn
ON pr.pizza_id = pn.pizza_id
ORDER BY pn.pizza_name;

-- 19. What was the most commonly added extra?
SELECT pt.topping_name, COUNT(j.extras) AS extra
FROM customer_orders AS co
JOIN JSON_TABLE(
	REPLACE (json_array(co.extras), ',', '","'),
	'$[*]' COLUMNS (extras VARCHAR(50) path '$')
) j
JOIN pizza_toppings AS pt
ON j.extras = pt.topping_id
WHERE co.extras <> "null" AND co.extras <> ""
GROUP BY pt.topping_name
LIMIT 1;

-- 20. What was the most common exlusion?
SELECT pt.topping_name, COUNT(j.exclusions) AS exclusion
FROM customer_orders AS co
JOIN JSON_TABLE(
	REPLACE (json_array(co.exclusions), ',', '","'),
	'$[*]' COLUMNS (exclusions VARCHAR(50) path '$')
) j
JOIN pizza_toppings AS pt
ON j.exclusions = pt.topping_id
WHERE co.exclusions <> "null" AND co.exclusions <> ""
GROUP BY pt.topping_name
LIMIT 1;

-- 21. Generate an order item for each record in the customer_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH RECURSIVE
EXTRAS AS (
	SELECT co.order_id, co.pizza_id, GROUP_CONCAT(pt.topping_name SEPARATOR ", ") AS added, co.extras
	FROM customer_orders AS co
	JOIN JSON_TABLE(
		REPLACE (json_array(co.extras), ',', '","'),
		'$[*]' COLUMNS (extras VARCHAR(50) path '$')
	) j
	JOIN pizza_toppings AS pt
	ON j.extras = pt.topping_id
	GROUP BY co.order_id, co.pizza_id, co.extras)
, EXCLUSIONS AS (
	SELECT co.order_id, co.pizza_id, GROUP_CONCAT(pt.topping_name SEPARATOR ", ") AS excluded, co.exclusions
	FROM customer_orders AS co
	JOIN JSON_TABLE(
		REPLACE (json_array(co.exclusions), ',', '","'),
		'$[*]' COLUMNS (exclusions VARCHAR(50) path '$')
	) j
	JOIN pizza_toppings AS pt
	ON j.exclusions = pt.topping_id
	GROUP BY co.order_id, co.pizza_id, co.exclusions)
SELECT CONCAT(
       CASE WHEN pn.pizza_name = "Meatlovers" THEN "Meat Lovers" ELSE pn.pizza_name END, 
       CONCAT(CASE WHEN added IS NULL THEN " " ELSE CONCAT(" - Extra ", added) END, ''), 
       CONCAT(CASE WHEN excluded IS NULL THEN " " ELSE CONCAT(" - Exclude ", excluded) END, '')
       ) AS order_detail
FROM customer_orders AS co
LEFT JOIN EXTRAS AS ext 
ON co.order_id = ext.order_id
AND co.pizza_id = ext.pizza_id
AND co.extras = ext.extras
LEFT JOIN EXCLUSIONS AS exc
ON co.order_id = exc.order_id
AND co.pizza_id = exc.pizza_id
AND co.exclusions = exc.exclusions
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id;

-- 22. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table
-- and add a 2x in front of every relevant ingredient (i.e. "Meat Lovers; 2xBacon, Cheese..."
WITH RECURSIVE
EXTRAS AS (
	SELECT co.order_id, co.pizza_id, pt.topping_id, co.extras, pt.topping_name AS added
	FROM customer_orders AS co
	JOIN JSON_TABLE(
		REPLACE (json_array(co.extras), ',', '","'),
		'$[*]' COLUMNS (extras VARCHAR(50) path '$')
	) j
	JOIN pizza_toppings AS pt
	ON j.extras = pt.topping_id
	GROUP BY 1, 2, 3, 4, 5)
, EXCLUSIONS AS (
	SELECT co.order_id, co.pizza_id, pt.topping_id, co.exclusions, pt.topping_name AS excluded
	FROM customer_orders AS co
	JOIN JSON_TABLE(
		REPLACE (json_array(co.exclusions), ',', '","'),
		'$[*]' COLUMNS (exclusions VARCHAR(50) path '$')
	) j
	JOIN pizza_toppings AS pt
	ON j.exclusions = pt.topping_id
	GROUP BY 1, 2, 3, 4, 5)
, ORDERS AS (
	SELECT co.order_id, co.pizza_id, j.toppings, pt.topping_name
    FROM customer_orders AS co
    INNER JOIN pizza_recipes AS pr
    ON co.pizza_id = pr.pizza_id
	JOIN JSON_TABLE(
		REPLACE (json_array(pr.toppings), ',', '","'),
		'$[*]' COLUMNS (toppings VARCHAR(50) path '$')
	) j
    INNER JOIN pizza_toppings AS pt
	ON j.toppings = pt.topping_id)
, ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS (SELECT o.order_id, o.pizza_id, o.toppings, o.topping_name
FROM ORDERS AS o
LEFT JOIN EXCLUSIONS AS exc
ON o.order_id = exc.order_id
AND o.pizza_id = exc.pizza_id
AND o.toppings = exc.topping_id
WHERE exc.topping_id IS NULL

UNION ALL

SELECT order_id, pizza_id, topping_id, added
FROM EXTRAS)
, INGREDIENTS AS (
	SELECT O.order_id, pn.pizza_name, O.topping_name, COUNT(toppings) AS n
	FROM ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS O
	INNER JOIN pizza_names AS pn
	ON pn.pizza_id = O.pizza_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 2, 3)
, INGREDIENT_LIST AS(
	SELECT order_id, pizza_name,
       GROUP_CONCAT(( CASE WHEN n>1 THEN CONCAT(n, "x", topping_name) ELSE topping_name END) SEPARATOR ", ") AS ING
	FROM INGREDIENTS
	GROUP BY 1, 2)
SELECT CONCAT( 
	CASE WHEN pizza_name = "Meatlovers" THEN "Meat Lovers" ELSE pizza_name END,
    "; ", ING) AS ingredient_list
FROM INGREDIENT_LIST
ORDER BY ingredient_list ASC;

-- 23. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH RECURSIVE
EXTRAS AS (
	SELECT co.order_id, co.pizza_id, pt.topping_id, co.extras, pt.topping_name AS added
	FROM customer_orders AS co
	JOIN JSON_TABLE(
		REPLACE (json_array(co.extras), ',', '","'),
		'$[*]' COLUMNS (extras VARCHAR(50) path '$')
	) j
	JOIN pizza_toppings AS pt
	ON j.extras = pt.topping_id
	GROUP BY 1, 2, 3, 4, 5)
, EXCLUSIONS AS (
	SELECT co.order_id, co.pizza_id, pt.topping_id, co.exclusions, pt.topping_name AS excluded
	FROM customer_orders AS co
	JOIN JSON_TABLE(
		REPLACE (json_array(co.exclusions), ',', '","'),
		'$[*]' COLUMNS (exclusions VARCHAR(50) path '$')
	) j
	JOIN pizza_toppings AS pt
	ON j.exclusions = pt.topping_id
	GROUP BY 1, 2, 3, 4, 5)
, ORDERS AS (
	SELECT co.order_id, co.pizza_id, j.toppings, pt.topping_name
    FROM customer_orders AS co
    INNER JOIN pizza_recipes AS pr
    ON co.pizza_id = pr.pizza_id
	JOIN JSON_TABLE(
		REPLACE (json_array(pr.toppings), ',', '","'),
		'$[*]' COLUMNS (toppings VARCHAR(50) path '$')
	) j
    INNER JOIN pizza_toppings AS pt
	ON j.toppings = pt.topping_id)
, ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS (SELECT o.order_id, o.pizza_id, o.toppings, o.topping_name
	FROM ORDERS AS o
	LEFT JOIN EXCLUSIONS AS exc
	ON o.order_id = exc.order_id
	AND o.pizza_id = exc.pizza_id
	AND o.toppings = exc.topping_id
	WHERE exc.topping_id IS NULL

	UNION ALL

	SELECT order_id, pizza_id, topping_id, added
	FROM EXTRAS)
SELECT topping_name, COUNT(topping_name) AS n
FROM ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS O
INNER JOIN runner_orders AS ro
ON O.order_id = ro.order_id
WHERE cancellation IS NULL OR cancellation = "null" OR cancellation = ""
GROUP BY topping_name
ORDER BY 2 DESC;