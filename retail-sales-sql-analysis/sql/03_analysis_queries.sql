-- Retail sales analysis: 10 business questions
-- Revenue per line = quantity * unit_price * (1 - order discount)
-- Profit per line  = revenue - quantity * unit_cost
-- Written to run on MySQL 8+ (also tested on SQLite 3.45).

-- Q1: What are the headline numbers?
SELECT COUNT(DISTINCT o.order_id) AS total_orders,
       COUNT(DISTINCT o.customer_id) AS active_customers,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)), 2) AS total_revenue,
       ROUND(SUM(oi.quantity * (p.unit_price * (1 - o.discount) - p.unit_cost)), 2) AS total_profit,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id;

-- Q2: How does revenue trend month over month?
WITH monthly AS (
    SELECT o.order_month,
           SUM(oi.quantity * p.unit_price * (1 - o.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY o.order_month
)
SELECT order_month,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
             / LAG(revenue) OVER (ORDER BY order_month), 1) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

-- Q3: Which categories earn the most revenue and the best margin?
SELECT p.category,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)), 2) AS revenue,
       ROUND(SUM(oi.quantity * (p.unit_price * (1 - o.discount) - p.unit_cost)), 2) AS profit,
       ROUND(100.0 * SUM(oi.quantity * (p.unit_price * (1 - o.discount) - p.unit_cost))
             / SUM(oi.quantity * p.unit_price * (1 - o.discount)), 1) AS margin_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Q4: Which 10 products drive the most revenue (with rank)?
SELECT RANK() OVER (ORDER BY SUM(oi.quantity * p.unit_price * (1 - o.discount)) DESC) AS revenue_rank,
       p.product_name,
       p.category,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)), 2) AS revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- Q5: How do regions and customer segments compare?
SELECT c.region,
       c.segment,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)), 2) AS revenue,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY c.region, c.segment
ORDER BY revenue DESC;

-- Q6: How concentrated is revenue? (share of revenue from each customer decile)
WITH cust AS (
    SELECT o.customer_id,
           SUM(oi.quantity * p.unit_price * (1 - o.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY o.customer_id
),
ranked AS (
    SELECT customer_id, revenue, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM cust
)
SELECT decile,
       COUNT(*) AS customers,
       ROUND(SUM(revenue), 2) AS revenue,
       ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM cust), 1) AS pct_of_total_revenue
FROM ranked
GROUP BY decile
ORDER BY decile;

-- Q7: What share of customers are repeat buyers, and how much more do they spend?
WITH cust AS (
    SELECT o.customer_id,
           COUNT(DISTINCT o.order_id) AS order_count,
           SUM(oi.quantity * p.unit_price * (1 - o.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY o.customer_id
)
SELECT CASE WHEN order_count = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cust), 1) AS pct_of_customers,
       ROUND(AVG(revenue), 2) AS avg_revenue_per_customer
FROM cust
GROUP BY CASE WHEN order_count = 1 THEN 'One-time' ELSE 'Repeat' END
ORDER BY customers DESC;

-- Q8: Online vs store: orders, average order value and profit margin
SELECT o.channel,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
       ROUND(100.0 * SUM(oi.quantity * (p.unit_price * (1 - o.discount) - p.unit_cost))
             / SUM(oi.quantity * p.unit_price * (1 - o.discount)), 1) AS margin_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.channel
ORDER BY orders DESC;

-- Q9: Do discounts pay off? Orders, revenue and margin by discount tier
SELECT o.discount,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - o.discount)), 2) AS revenue,
       ROUND(100.0 * SUM(oi.quantity * (p.unit_price * (1 - o.discount) - p.unit_cost))
             / SUM(oi.quantity * p.unit_price * (1 - o.discount)), 1) AS margin_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.discount
ORDER BY o.discount;

-- Q10: What is the best-selling category (by units) in each region?
WITH reg_cat AS (
    SELECT c.region, p.category,
           SUM(oi.quantity) AS units_sold,
           SUM(oi.quantity * p.unit_price * (1 - o.discount)) AS revenue
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY c.region, p.category
),
ranked AS (
    SELECT region, category, units_sold, revenue,
           RANK() OVER (PARTITION BY region ORDER BY units_sold DESC) AS rnk
    FROM reg_cat
)
SELECT region, category, units_sold, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rnk = 1
ORDER BY region;
