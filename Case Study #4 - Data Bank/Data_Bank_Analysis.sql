-- Use Database
USE data_bank;

/* CUSTOMER NODES EXPLORATION
1. How many unique nodes are there on the Data Bank system? */
SELECT COUNT(DISTINCT(node_id)) AS count_unique_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT region_name, COUNT(DISTINCT(node_id)) AS nodes_per_region
FROM customer_nodes AS cn
JOIN regions AS r
ON cn.region_id = r.region_id
GROUP BY region_name;

-- 3. How many customers are allocated to each region?
SELECT region_name, COUNT(DISTINCT(customer_id)) AS customers_per_region
FROM customer_nodes AS cn
JOIN regions AS r
ON cn.region_id = r.region_id
GROUP BY region_name;

-- 4. How many days on average are customers reallocated to a different node?
WITH CTE AS (
	SELECT customer_id, node_id, SUM(DATEDIFF(end_date, start_date)) AS total_days_per_node
	FROM customer_nodes
    WHERE end_date <> "9999-12-31"
    GROUP BY 1, 2
    )
SELECT ROUND(AVG(total_days_per_node), 0) AS avg_days_per_node
FROM CTE;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH CTE AS (
	SELECT region_name, customer_id, node_id, SUM(DATEDIFF(end_date, start_date)) AS total_days_per_node
	FROM customer_nodes AS cn
    INNER JOIN regions AS r
    ON cn.region_id = r.region_id
    WHERE end_date <> "9999-12-31"
    GROUP BY 1, 2, 3
    )
,ORDERED AS (
	SELECT region_name, total_days_per_node, ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY total_days_per_node) as rn
	FROM CTE
)
,MAX_ROWS as (
	SELECT region_name, MAX(rn) as max_rn
	FROM ORDERED
	GROUP BY region_name
)
SELECT o.region_name, CASE 
	WHEN rn = ROUND(M.max_rn / 2,0) THEN "Median"
	WHEN rn = ROUND(M.max_rn * 0.8,0) THEN "80th Percentile"
	WHEN rn = ROUND(M.max_rn * 0.95,0) THEN "95th Percentile"
	END AS metric,
total_days_per_node AS value
FROM ORDERED AS o
INNER JOIN MAX_ROWS AS m 
ON m.region_name = o.region_name
WHERE rn IN (
    ROUND(M.max_rn /2,0),
    ROUND(M.max_rn * 0.8,0),
	ROUND(M.max_rn * 0.95,0)
	);

/* CUSTOMER TRANSACTIONS
6. What is the unique count and total amount for each transaction type? */
SELECT txn_type, SUM(txn_amount) as total_amount, COUNT(*) AS transcation_count
FROM customer_transactions
GROUP BY txn_type;

-- 7. What is the average total historical deposit counts and amounts for all customers
WITH CTE AS (
	SELECT customer_id, AVG(txn_amount) as avg_deposit, COUNT(*) AS transaction_count
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
	)
SELECT ROUND(AVG(avg_deposit), 0) as avg_deposit_amount, ROUND(AVG(transaction_count), 0) AS avg_transactions
FROM CTE;

-- 8. For each month how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH CTE AS (
	SELECT MONTH(txn_date) as month, customer_id,
		   SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposits,
		   SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) AS purchase_or_withdrawal
	FROM customer_transactions
	GROUP BY 1, 2
	HAVING SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) > 1
	AND SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) = 1
	)
SELECT month, COUNT(customer_id) as customers
FROM CTE
GROUP BY month;
