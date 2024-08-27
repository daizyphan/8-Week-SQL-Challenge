-- Database: danny_dinner

-- DROP DATABASE IF EXISTS "danny's_dinner";

CREATE DATABASE "dannys_dinner"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_spent
FROM sales AS s
LEFT JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date))
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH order_sales AS (
	SELECT
		s.customer_id,
		order_date,
		product_name,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY order_date) AS rank
		FROM sales AS s
		LEFT JOIN menu AS m
			ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM order_sales
WHERE rank = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(s.product_id) AS number_orders
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY number_orders DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH popular_items AS (
	SELECT customer_id, COUNT(s.product_id), product_name,
	DENSE_RANK() OVER(
		PARTITION BY customer_id
		ORDER BY COUNT(s.product_id) DESC) AS rank
	FROM sales AS s
	LEFT JOIN menu AS m
		ON s.product_id = m.product_id
	GROUP BY customer_id, product_name
)
SELECT customer_id, product_name
FROM popular_items
WHERE rank = 1
GROUP BY customer_id, product_name;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_items AS (
	SELECT s.customer_id, product_id,
	ROW_NUMBER() OVER(
		PARTITION BY s.customer_id
		ORDER BY order_date) AS row_num
	FROM sales AS s
	RIGHT JOIN members AS mb
	ON s.customer_id = mb.customer_id
	AND order_date > join_date
)
SELECT customer_id, product_name
FROM first_items AS fi
LEFT JOIN menu AS m
	ON 	fi.product_id = m.product_id
WHERE row_num = 1
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
WITH last_items AS (
	SELECT s.customer_id, product_id,
	ROW_NUMBER() OVER(
		PARTITION BY s.customer_id
		ORDER BY order_date DESC) AS row_num
	FROM sales AS s
	RIGHT JOIN members AS mb
	ON s.customer_id = mb.customer_id
	AND order_date < join_date
)
SELECT customer_id, product_name
FROM last_items AS fi
LEFT JOIN menu AS m
	ON 	fi.product_id = m.product_id
WHERE row_num = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 	s.customer_id, COUNT(DISTINCT(product_name)), SUM(price)
FROM sales AS s
JOIN members AS mb
ON s.customer_id = mb.customer_id
AND order_date < join_date
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH total_points AS (
	SELECT customer_id,
		CASE 
			WHEN s.product_id = '1' THEN price * 20
			ELSE price * 10 END AS points
	FROM sales AS s
	LEFT JOIN menu AS m
	ON s.product_id = m.product_id
)

SELECT customer_id, SUM(points)
FROM total_points
GROUP BY customer_id
ORDER BY customer_id;
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS (
	SELECT customer_id, join_date,
			join_date + 6 AS valid_date,
			DATE_TRUNC('month', '2021-01-31' :: DATE) 
						+ interval '1 month'
						- interval '1 day' AS last_date
			FROM members
)
SELECT s.customer_id,
		SUM(CASE 
			WHEN s.product_id = '1' THEN 20 * price
			WHEN order_date BETWEEN join_date AND valid_date THEN 20 * price
			ELSE 10 * price
			END) AS points
FROM sales AS s
JOIN dates AS d
	ON s.customer_id = d.customer_id
	AND d.join_date <= s.order_date
	AND s.order_date <= last_date
JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;