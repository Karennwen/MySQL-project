-- 1. Initialize the CTE for all created carts
WITH
total_carts_created as 
(
     SELECT 
	     *
     FROM 
	     checkout_carts
),

-- 2. Select data on users who created a purchase cart and attempted to finalize a purchase
total_checkout_attempts as
(
	SELECT
        tc.user_id,
        a.action_name,
        a.action_date
    FROM 
        total_carts_created as tc
    LEFT JOIN 
        checkout_actions as a on a.user_id = tc.user_id
    WHERE
        a.action_name like '%checkout%'
        AND 
        a.action_date BETWEEN '2022-07-01' AND '2023-01-31'
),

-- 3. Construct a temporary result set for successful checkout attempts
total_successful_attempts as
(
	SELECT
        a.user_id,
        a.action_name,
        a.action_date
    FROM 
        total_checkout_attempts as a
    WHERE
        a.action_name like '%.success'
    GROUP BY a.user_id
),

-- 4. Count the total number of carts from all purchased carts daily
count_total_carts as
(
    SELECT
        action_date,
        COUNT(*) as count_total_carts
    FROM 
        total_carts_created 
    GROUP BY action_date
),

-- 5. Count the total daily checkout attempts
count_total_checkout_attempts as
(
    SELECT
        action_date,
        COUNT(*) as count_total_checkout_attempts
    FROM
        total_checkout_attempts
    GROUP BY action_date
),

-- 6. Count only the successful daily attempts
count_successful_checkout_attempts as
(
    SELECT
        action_date,
        COUNT(*) as count_successful_checkout_attempts
    FROM 
        total_successful_attempts
    GROUP BY action_date
),

-- 7. Select pertinent data from the last three CTEs and construct the final result set
checkout_steps AS (
    SELECT
        c.action_date,
        IFNULL(c.count_total_carts, 0) AS count_total_carts,
        IFNULL(a.count_total_checkout_attempts, 0) AS count_total_checkout_attempts,
        IFNULL(s.count_successful_checkout_attempts, 0) AS count_successful_checkout_attempts
    FROM
        count_total_carts c
    LEFT JOIN 
        count_total_checkout_attempts a ON a.action_date = c.action_date
    LEFT JOIN 
        count_successful_checkout_attempts s ON s.action_date = a.action_date
    WHERE
        c.action_date BETWEEN '2022-07-01' AND '2023-01-31'
    ORDER BY c.action_date
)

SELECT * FROM checkout_steps;

-- create a new table called checkout errors
SELECT 
    user_id, 
    action_date, 
    action_name, 
    error_message, 
    device
FROM
    checkout_actions
WHERE 
    action_date BETWEEN '2022-07-01' AND '2023-01-31' 
    AND action_name LIKE '%checkout%'
    AND error_message IS NOT NULL -- Include only events with errors
GROUP BY user_id
ORDER BY action_date;
