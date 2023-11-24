-- Use Database
USE foodie_fi;

/* CUSTOMER JOURNEY
1. Based off the 8 sample customers provided in the sample from the subscriptions table, 
write a brief description about each customer’s onboarding journey. Try to keep it as short as possible */
SELECT customer_id, plan_name, price, start_date
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE customer_id <= 10;

/* DATA ANALYSIS QUESTIONS
2. How many customers has Foodie_Fi ever had? */
SELECT COUNT(DISTINCT(customer_id)) AS customer_count
FROM subscriptions;

-- 3. What is the monthly distribution of trial plan start_date values for our dataset
WITH month_name AS (
	SELECT *, MONTHNAME(start_date) AS month
	FROM subscriptions
)
SELECT month, COUNT(customer_id) AS trial_starts
FROM month_name
WHERE plan_id = 0
GROUP BY month;

-- 4. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name, COUNT(*) AS count_of_events
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY p.plan_name;

-- 5. What is the customer count and percentage of customers who have churned?
SELECT (
	SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions) AS customer_count,
    ROUND(COUNT(DISTINCT(s.customer_id)) / (SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions)*100, 2) AS churned_customers_percentage
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE s.plan_id = 4;

-- 6. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH CTE AS(
	SELECT s.customer_id, p.plan_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS row_num
	FROM subscriptions AS s
	JOIN plans AS p
	ON s.plan_id = p.plan_id)
SELECT COUNT(DISTINCT(customer_id)) AS churned_after_trial_customers,
	   ROUND(COUNT(DISTINCT(customer_id)) / (SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions)*100, 0) 
	   AS churned_after_trial_customers_percentage
FROM CTE
WHERE row_num = 2 AND plan_name = "churn";

-- 7. What is the number and percentage of customer plans after their initial free trial?
WITH CTE AS(
	SELECT s.customer_id, p.plan_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS row_num
	FROM subscriptions AS s
	JOIN plans AS p
	ON s.plan_id = p.plan_id)
SELECT plan_name,
	   COUNT(DISTINCT(customer_id)) AS plans_after_trial,
	   ROUND(COUNT(DISTINCT(customer_id)) / (SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions)*100, 0) 
	   AS plans_after_trial_percentage
FROM CTE
WHERE row_num = 2 
GROUP BY plan_name;

-- 8. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS row_num
	FROM subscriptions
	WHERE start_date <= "2020-12-31")
SELECT p.plan_name, 
	   COUNT(c.customer_id) AS customer_count,
       ROUND(COUNT(c.customer_id) / (SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions)*100, 1) AS customer_percentage
FROM CTE AS c
JOIN plans AS p
ON c.plan_id = p.plan_id
WHERE c.row_num = 1
GROUP BY 1
ORDER BY 2;

-- 9. How many customers have upgraded to an annual plan in 2020?
WITH monthly_customers AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE YEAR(start_date) <= 2020
	AND plan_id IN (1,2)
),
annual_customers AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE YEAR(start_date) <= 2020
	AND plan_id IN (1,2)
)
SELECT COUNT(DISTINCT a.customer_id) as annual_upgrade_customers
FROM monthly_customers AS m
INNER JOIN annual_customers AS a
ON m.customer_id = a.customer_id 
AND m.start_date < a.start_date;

-- 10. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trial AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE plan_id = 0
), 
annual AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE plan_id = 3
)
SELECT 
ROUND(AVG(DATEDIFF(a.start_date, t.start_date)),0) AS average_days_from_trial_to_annual
FROM trial AS t
INNER JOIN annual AS a 
ON t.customer_id = a.customer_id;

-- 11. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE plan_id = 0
), 
annual AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE plan_id = 3
)
SELECT 
CASE
WHEN DATEDIFF(a.start_date, t.start_date) <= 30  THEN '0-30'
WHEN DATEDIFF(a.start_date, t.start_date) <= 60  THEN '31-60'
WHEN DATEDIFF(a.start_date, t.start_date) <= 90  THEN '61-90'
WHEN DATEDIFF(a.start_date, t.start_date) <= 120  THEN '91-120'
WHEN DATEDIFF(a.start_date, t.start_date) <= 150  THEN '121-150'
WHEN DATEDIFF(a.start_date, t.start_date) <= 180  THEN '151-180'
WHEN DATEDIFF(a.start_date, t.start_date) <= 210  THEN '181-210'
WHEN DATEDIFF(a.start_date, t.start_date) <= 240  THEN '211-240'
WHEN DATEDIFF(a.start_date, t.start_date) <= 270  THEN '241-270'
WHEN DATEDIFF(a.start_date, t.start_date) <= 300  THEN '271-300'
WHEN DATEDIFF(a.start_date, t.start_date) <= 330  THEN '301-330'
WHEN DATEDIFF(a.start_date, t.start_date) <= 360  THEN '331-360'
END as 30_days_period,
COUNT(t.customer_id) as customer_count
FROM trial AS t
INNER JOIN annual AS a
ON t.customer_id = a.customer_id
GROUP BY 1;

-- 12. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH pro_monthly AS (
	SELECT customer_id, start_date
	FROM subscriptions
	WHERE plan_id = 2
),
basic_monthly AS (
	SELECT customer_id, start_date 
	FROM subscriptions
	WHERE plan_id = 1
)
SELECT p.customer_id, p.start_date, b.start_date
FROM pro_monthly AS p
INNER JOIN basic_monthly AS b
ON p.customer_id = b.customer_id
WHERE p.start_date < b.start_date
AND YEAR(b.start_date) = 2020;
