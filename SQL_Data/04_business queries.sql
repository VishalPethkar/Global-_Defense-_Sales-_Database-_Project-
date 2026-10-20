USE global_defense_sales;

-- 1. Overall business summary (KPIs)
SELECT COUNT(*)                                              AS total_orders,
       COUNT(DISTINCT customer_id)                           AS unique_customers,
       SUM(order_quantity)                                   AS units_sold,
       ROUND(SUM(unit_selling_price*order_quantity*(1-discount_applied)),2) AS net_revenue,
       ROUND(SUM(net_profit),2)                              AS total_profit,
       ROUND(SUM(net_profit)/SUM(unit_selling_price*order_quantity*(1-discount_applied))*100,2) AS profit_margin_pct
FROM sales_data
WHERE order_status = 'Completed';


-- 2. Order status breakdown (return and cancel rate)
SELECT order_status,
       COUNT(*) AS orders,
       ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER (),2) AS pct_of_orders
FROM sales_data
GROUP BY order_status
ORDER BY orders DESC;


-- 3. Profit by region
SELECT customer_region,
       COUNT(*) AS orders,
       ROUND(SUM(net_profit),2) AS total_profit,
       ROUND(AVG(net_profit),2) AS avg_profit_per_order
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY customer_region
ORDER BY total_profit DESC;



-- 4. Top 10 products by profit
SELECT product_name, product_category,
       SUM(order_quantity) AS units_sold,
       ROUND(SUM(net_profit),2) AS total_profit
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY product_name, product_category
ORDER BY total_profit DESC
LIMIT 10;


-- 5. Category performance with margin
SELECT product_category,
       ROUND(SUM(unit_selling_price*order_quantity*(1-discount_applied)),2) AS revenue,
       ROUND(SUM(net_profit),2) AS profit,
       ROUND(SUM(net_profit)/SUM(unit_selling_price*order_quantity*(1-discount_applied))*100,2) AS margin_pct
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY profit DESC;


-- 6. Monthly profit trend
SELECT DATE_FORMAT(order_date,'%Y-%m') AS month,
       COUNT(*) AS orders,
       ROUND(SUM(net_profit),2) AS profit
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY month
ORDER BY month;


-- 7. Year-over-year growth
WITH yearly AS (
  SELECT YEAR(order_date) AS yr, SUM(net_profit) AS profit
  FROM sales_data
  WHERE order_status = 'Completed'
  GROUP BY YEAR(order_date)
)
SELECT yr, ROUND(profit,2) AS profit,
       ROUND((profit - LAG(profit) OVER (ORDER BY yr)) / LAG(profit) OVER (ORDER BY yr) * 100,2) AS yoy_growth_pct
FROM yearly;


-- 8. Customer segment analysis
SELECT customer_segment,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(*) AS orders,
       ROUND(SUM(net_profit),2) AS profit
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY customer_segment
ORDER BY profit DESC;


-- 9. Top 10 customers
SELECT customer_id, customer_country, customer_segment,
       COUNT(*) AS orders,
       ROUND(SUM(net_profit),2) AS total_profit
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY customer_id, customer_country, customer_segment
ORDER BY total_profit DESC
LIMIT 10;


-- 10. Supplier performance
SELECT supplier_name,
       COUNT(*) AS orders,
       ROUND(SUM(net_profit),2) AS profit,
       ROUND(SUM(order_status='Returned')*100.0/COUNT(*),2) AS return_rate_pct
FROM sales_data
GROUP BY supplier_name
ORDER BY profit DESC;


-- 11. Does discounting hurt profit?
SELECT discount_applied,
       COUNT(*) AS orders,
       ROUND(AVG(net_profit),2) AS avg_profit_per_order,
       ROUND(AVG(unit_selling_price - unit_cost),2) AS avg_unit_margin
FROM sales_data
WHERE order_status = 'Completed'
GROUP BY discount_applied
ORDER BY discount_applied;


-- 12. Loss-making completed orders
SELECT order_id, product_name, customer_country, discount_applied, net_profit
FROM sales_data
WHERE order_status = 'Completed' AND net_profit < 0
ORDER BY net_profit
LIMIT 20;


-- 13. Average shipping time by region
SELECT customer_region,
       ROUND(AVG(DATEDIFF(ship_date, order_date)),2) AS avg_days_to_ship
FROM sales_data
GROUP BY customer_region
ORDER BY avg_days_to_ship;


-- 14. Rank products inside each category (window function)
SELECT * FROM (
  SELECT product_category, product_name,
         ROUND(SUM(net_profit),2) AS profit,
         RANK() OVER (PARTITION BY product_category ORDER BY SUM(net_profit) DESC) AS rnk
  FROM sales_data
  WHERE order_status = 'Completed'
  GROUP BY product_category, product_name
) t
WHERE rnk <= 3;


-- 15. Return value lost: which products come back most
SELECT product_name,
       COUNT(*) AS total_orders,
       SUM(order_status='Returned') AS returned_orders,
       ROUND(SUM(order_status='Returned')*100.0/COUNT(*),2) AS return_rate_pct
FROM sales_data
GROUP BY product_name
ORDER BY return_rate_pct DESC
LIMIT 10;