-- =====================================================================
-- Global Defense Sales Analytics | SQL companion (tested on SQLite 3)
-- Tables: Fact_Sales, Dim_Product, Dim_Customer, Dim_Date (load the CSVs in /data)
-- Dialect notes: for SQL Server replace strftime() with YEAR()/MONTH(),
--   and LIMIT n with TOP n. Window functions work as written in
--   PostgreSQL, SQL Server 2012+, MySQL 8+ and SQLite 3.25+.
-- Business rule used everywhere: realised = Order_Status = 'Completed'
-- =====================================================================

-- Q01. Headline KPIs (realised)
SELECT COUNT(*)                              AS completed_orders,
       COUNT(DISTINCT Customer_ID)           AS active_customers,
       ROUND(SUM(Net_Revenue)/1e9, 2)        AS revenue_bn,
       ROUND(SUM(Net_Profit)/1e9, 2)         AS profit_bn,
       ROUND(100.0*SUM(Net_Profit)/SUM(Net_Revenue), 2) AS margin_pct,
       ROUND(SUM(Net_Revenue)/COUNT(*), 0)   AS avg_order_value
FROM Fact_Sales
WHERE Order_Status = 'Completed';

-- Q02. Fiscal-year revenue, profit and YoY growth (FY starts 1 October)
WITH fy AS (
  SELECT d.Fiscal_Year,
         SUM(f.Net_Revenue) AS revenue,
         SUM(f.Net_Profit)  AS profit
  FROM Fact_Sales f
  JOIN Dim_Date d ON d.Date = f.Order_Date
  WHERE f.Order_Status = 'Completed'
  GROUP BY d.Fiscal_Year)
SELECT Fiscal_Year,
       ROUND(revenue/1e9, 2) AS revenue_bn,
       ROUND(profit/1e9, 2)  AS profit_bn,
       ROUND(100.0*(revenue - LAG(revenue) OVER (ORDER BY Fiscal_Year))
             / LAG(revenue) OVER (ORDER BY Fiscal_Year), 2) AS revenue_yoy_pct
FROM fy ORDER BY Fiscal_Year;

-- Q03. Margin erosion by discount band
SELECT Discount_Band,
       COUNT(*)                                           AS orders,
       ROUND(SUM(Net_Revenue)/1e9, 2)                     AS revenue_bn,
       ROUND(100.0*SUM(Net_Profit)/SUM(Net_Revenue), 1)   AS margin_pct,
       SUM(Is_Loss_Making)                                AS loss_making_orders
FROM Fact_Sales
WHERE Order_Status = 'Completed'
GROUP BY Discount_Band
ORDER BY CASE Discount_Band WHEN '0%' THEN 1 WHEN '1-5%' THEN 2 WHEN '6-10%' THEN 3
                            WHEN '11-15%' THEN 4 ELSE 5 END;

-- Q04. Loss-making orders: where do they start, how big are they?
SELECT ROUND(MIN(Discount_Applied), 2)                 AS lowest_discount_with_a_loss,
       COUNT(*)                                        AS loss_orders,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM Fact_Sales
                             WHERE Order_Status='Completed'), 2) AS pct_of_completed,
       ROUND(SUM(Net_Profit)/1e6, 1)                   AS total_loss_m
FROM Fact_Sales
WHERE Is_Loss_Making = 1;

-- Q05. Revenue leakage by order status
SELECT Order_Status,
       COUNT(*)                                                 AS orders,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (), 1)           AS pct_orders,
       ROUND(SUM(Net_Revenue)/1e9, 2)                           AS order_value_bn
FROM Fact_Sales
GROUP BY Order_Status
ORDER BY orders DESC;

-- Q06. Top 10 products by profit with cumulative share (Pareto)
WITH p AS (
  SELECT dp.Product_Name, SUM(f.Net_Profit) AS profit
  FROM Fact_Sales f JOIN Dim_Product dp USING (Product_ID)
  WHERE f.Order_Status = 'Completed'
  GROUP BY dp.Product_Name)
SELECT Product_Name,
       ROUND(profit/1e9, 2) AS profit_bn,
       ROUND(100.0*SUM(profit) OVER (ORDER BY profit DESC)
             / SUM(profit) OVER (), 1) AS cumulative_share_pct
FROM p ORDER BY profit DESC LIMIT 10;

-- Q07. Supplier concentration
SELECT dp.Supplier_Short,
       ROUND(SUM(f.Net_Revenue)/1e9, 2) AS revenue_bn,
       ROUND(100.0*SUM(f.Net_Revenue)/SUM(SUM(f.Net_Revenue)) OVER (), 1) AS share_pct
FROM Fact_Sales f JOIN Dim_Product dp USING (Product_ID)
WHERE f.Order_Status = 'Completed'
GROUP BY dp.Supplier_Short
ORDER BY revenue_bn DESC LIMIT 5;

-- Q08. Revenue and margin by category
SELECT dp.Product_Category,
       ROUND(SUM(f.Net_Revenue)/1e9, 2)                      AS revenue_bn,
       ROUND(100.0*SUM(f.Net_Revenue)/SUM(SUM(f.Net_Revenue)) OVER (), 1) AS share_pct,
       ROUND(100.0*SUM(f.Net_Profit)/SUM(f.Net_Revenue), 1)  AS margin_pct
FROM Fact_Sales f JOIN Dim_Product dp USING (Product_ID)
WHERE f.Order_Status = 'Completed'
GROUP BY dp.Product_Category
ORDER BY revenue_bn DESC;

-- Q09. Region and country performance
SELECT dc.Customer_Region, dc.Customer_Country,
       ROUND(SUM(f.Net_Revenue)/1e9, 2)                      AS revenue_bn,
       ROUND(100.0*SUM(f.Net_Profit)/SUM(f.Net_Revenue), 1)  AS margin_pct
FROM Fact_Sales f JOIN Dim_Customer dc USING (Customer_ID)
WHERE f.Order_Status = 'Completed'
GROUP BY dc.Customer_Region, dc.Customer_Country
ORDER BY revenue_bn DESC;

-- Q10. Customer concentration: share of revenue from the top 10% of customers
WITH c AS (
  SELECT Customer_ID, SUM(Net_Revenue) AS rev
  FROM Fact_Sales WHERE Order_Status = 'Completed'
  GROUP BY Customer_ID),
r AS (
  SELECT rev, ROW_NUMBER() OVER (ORDER BY rev DESC) AS rn, COUNT(*) OVER () AS n FROM c)
SELECT ROUND(100.0*SUM(CASE WHEN rn <= CAST((n*0.1)+0.999999 AS INT) THEN rev END)/SUM(rev), 1)
         AS top10pct_customer_share
FROM r;

-- Q11. Monthly revenue with 3-month moving average
WITH m AS (
  SELECT d.Year_Month, SUM(f.Net_Revenue) AS revenue
  FROM Fact_Sales f JOIN Dim_Date d ON d.Date = f.Order_Date
  WHERE f.Order_Status = 'Completed'
  GROUP BY d.Year_Month)
SELECT Year_Month,
       ROUND(revenue/1e9, 2) AS revenue_bn,
       ROUND(AVG(revenue) OVER (ORDER BY Year_Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)/1e9, 2) AS ma3_bn
FROM m ORDER BY Year_Month LIMIT 12;

-- Q12. Discount-cap what-if (same volume): profit if discounts above the cap are trimmed to the cap
WITH caps(cap) AS (VALUES (0.05),(0.10),(0.12),(0.15),(0.20))
SELECT cap AS discount_cap,
       ROUND(SUM((Unit_Selling_Price*(1 - MIN(Discount_Applied, cap)) - Unit_Cost)*Order_Quantity)/1e9, 2) AS profit_bn,
       ROUND((SUM((Unit_Selling_Price*(1 - MIN(Discount_Applied, cap)) - Unit_Cost)*Order_Quantity)
              - SUM(Net_Profit))/1e9, 2) AS uplift_bn
FROM Fact_Sales, caps
WHERE Order_Status = 'Completed'
GROUP BY cap ORDER BY cap;

-- Q13. Is the return rate really uniform? (by region)
SELECT dc.Customer_Region,
       ROUND(100.0*SUM(CASE WHEN f.Order_Status='Returned' THEN 1 ELSE 0 END)/COUNT(*), 2) AS return_rate_pct
FROM Fact_Sales f JOIN Dim_Customer dc USING (Customer_ID)
GROUP BY dc.Customer_Region ORDER BY return_rate_pct DESC;

-- Q14. RFM segment summary
SELECT RFM_Segment,
       COUNT(*)                                    AS customers,
       ROUND(SUM(Lifetime_Revenue)/1e9, 2)                 AS revenue_bn,
       ROUND(100.0*SUM(Lifetime_Revenue)/SUM(SUM(Lifetime_Revenue)) OVER (), 1) AS revenue_share_pct
FROM Dim_Customer
WHERE RFM_Segment <> 'No Completed Orders'
GROUP BY RFM_Segment ORDER BY revenue_bn DESC;

-- Q15. Shipping-days distribution
SELECT Ship_Days, COUNT(*) AS orders,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (), 1) AS pct
FROM Fact_Sales GROUP BY Ship_Days ORDER BY Ship_Days;
