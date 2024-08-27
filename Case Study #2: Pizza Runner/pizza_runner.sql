-- Database: pizza_runner

-- DROP DATABASE IF EXISTS pizza_runner;

CREATE DATABASE pizza_runner
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', '', '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', '', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', '', '', '2020-01-08 21:03:13'),
  ('7', '105', '2', '', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', '', '', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', '', '', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

/*
A. Pizza Metrics
*/
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS num_pizza_order
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) AS unique_order
FROM customer_orders;
-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS sucess_orders
FROM runner_orders
WHERE distance NOT LIKE 'null'
GROUP BY runner_id;
-- 4. How many of each type of pizza was delivered?
SELECT pizza_name, COUNT(co.order_id) AS num_pizza
FROM customer_orders AS co
INNER JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
LEFT JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
WHERE distance NOT LIKE 'null'
GROUP BY pizza_name;
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(co.order_id) AS num_pizza
FROM customer_orders AS co
LEFT JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY customer_id;
-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(pizza_id) AS num_pizza
FROM customer_orders
GROUP BY order_id
ORDER BY num_pizza DESC
LIMIT 1;
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
		SUM(
			CASE WHEN (exclusions != '') OR (extras != '') THEN 1
				ELSE 0 END) AS at_least_1_change,
		SUM(
			CASE WHEN (exclusions = '') OR (extras = '') THEN 1
				ELSE 0 END) AS no_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE distance NOT LIKE 'null'
GROUP BY customer_id
ORDER BY customer_id;		
-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
		SUM(
			CASE WHEN (exclusions != '') AND (extras != '') THEN 1
				ELSE 0 END) AS both_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE distance NOT LIKE 'null';
-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATE_PART('hour', order_time) AS hour_of_day,
		COUNT(pizza_id) AS pizza_count
FROM customer_orders
GROUP BY DATE_PART('hour', order_time)
ORDER BY hour_of_day;
-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time, 'Day') AS day_of_week,
		COUNT(order_id) AS order_count
FROM customer_orders
GROUP BY TO_CHAR(order_time, 'Day');
/*
B. Runner and Customer Experience
*/
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATE_PART('week', registration_date) AS week,
		COUNT(runner_id) AS runners_per_week
FROM runners
GROUP BY DATE_PART('week', registration_date);
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH duration AS (
	SELECT 
		runner_id,
		co.order_id,
		(DATE_PART('hour', pickup_time::timestamp - order_time::timestamp) * 60 + 
		DATE_PART('minute', pickup_time::timestamp - order_time::timestamp)) AS pickup_minutes
	FROM customer_orders AS co
	LEFT JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
	WHERE distance NOT LIKE 'null'
	GROUP BY runner_id, co.order_id, order_time, pickup_time
)
SELECT runner_id,
		AVG(pickup_minutes) AS avg_pickup_minutes
FROM duration
WHERE pickup_minutes > 0
GROUP BY runner_id
ORDER BY runner_id;
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH relationship AS (
	SELECT co.order_id,
		pizza_id,
		(DATE_PART('hour', pickup_time:: timestamp - order_time::timestamp) * 60 +
		DATE_PART('minute', pickup_time::timestamp - order_time::timestamp)) AS prepare_time
	FROM customer_orders AS co
	LEFT JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
	WHERE distance NOT LIKE 'null'
	GROUP BY co.order_id, pizza_id, pickup_time, order_time
)
SELECT order_id,
		COUNT(pizza_id) AS num_of_pizza,
		prepare_time
FROM relationship
WHERE prepare_time > 0
GROUP BY order_id, prepare_time
ORDER BY order_id;
-- 4. What was the average distance travelled for each customer?
UPDATE runner_orders
SET distance = regexp_replace(distance, '[^0-9\.]', '', 'g');

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE numeric
USING coalesce(nullif(distance, '')::numeric, 0);

SELECT customer_id,
		ROUND(AVG(distance), 2) AS avg_distance
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE distance != 0
GROUP BY customer_id
ORDER BY customer_id;
-- 5. What was the difference between the longest and shortest delivery times for all orders?
UPDATE runner_orders
SET duration = regexp_replace(duration, '[^0-9\.]', '', 'g');

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE numeric
USING COALESCE(nullif(duration, '')::numeric, 0);

SELECT MAX(duration) - MIN(duration) AS diff_time
FROM runner_orders
WHERE duration != 0;
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 	runner_id,
		order_id,
		distance,
		duration,
		ROUND((distance / (duration/60)), 2) AS speed
FROM runner_orders
WHERE distance != 0
AND duration != 0
GROUP BY runner_id, order_id, distance, duration
ORDER BY runner_id;
-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id,
		ROUND(100 * 
			SUM(
				CASE WHEN distance != 0 THEN 1
				ELSE 0 END
			)/COUNT(*), 2) AS success_percentage
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;
/*
C. Ingredient Optimisation
*/
-- 1. What are the standard ingredients for each pizza?
WITH std_ins AS (
	SELECT pizza_id, 
			REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
	FROM pizza_recipes
)
SELECT pizza_id, topping_name
FROM std_ins AS si
LEFT JOIN pizza_toppings AS pt
	ON si.topping_id = pt.topping_id
ORDER BY pizza_id;
-- 2. What was the most commonly added extra?
WITH common_extra AS (
	SELECT co.pizza_id,
			REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+')::CHAR AS extras
	FROM customer_orders AS co
	LEFT JOIN pizza_recipes AS pr
		ON co.pizza_id = pr.pizza_id
)
SELECT  topping_name,
		COUNT(extras) AS extra
FROM common_extra AS ce
LEFT JOIN pizza_toppings AS pt
	ON CAST(ce.extras AS INT) = pt.topping_id
WHERE ce.extras != ''
GROUP BY topping_name;
-- 3. What was the most common exclusion?
WITH common_exclusions AS (
	SELECT co.pizza_id,
			REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::CHAR AS exclusions
	FROM customer_orders AS co
	LEFT JOIN pizza_recipes AS pr
		ON co.pizza_id = pr.pizza_id
)
SELECT  topping_name,
		COUNT(exclusions) AS exclusion
FROM common_exclusions AS ce
LEFT JOIN pizza_toppings AS pt
	ON CAST(ce.exclusions AS INT) = pt.topping_id
WHERE ce.exclusions != ''
GROUP BY topping_name;