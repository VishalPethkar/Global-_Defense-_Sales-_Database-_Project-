-- schema for the global defense sales project (mysql 8)
-- data comes from Global_Defense_Sales_Data_500K.xlsx converted to sales.csv

CREATE DATABASE IF NOT EXISTS global_defense_sales;

USE global_defense_sales;

-- one row per order (500,000 orders, 2023-10 to 2026-10)
-- no primary key yet, it is added after the load in 03_indexes.sql
CREATE TABLE IF NOT EXISTS sales_data (
  order_id            VARCHAR(20)   NOT NULL,
  order_date          DATE          NOT NULL,
  ship_date           DATE          NOT NULL,
  order_status        VARCHAR(15)   NOT NULL,  -- Completed / Returned / Cancelled / Pending
  customer_id         VARCHAR(15)   NOT NULL,
  customer_segment    VARCHAR(30)   NOT NULL,
  customer_country    VARCHAR(30)   NOT NULL,
  customer_region     VARCHAR(30)   NOT NULL,
  product_id          VARCHAR(15)   NOT NULL,
  product_name        VARCHAR(60)   NOT NULL,
  product_category    VARCHAR(30)   NOT NULL,
  supplier_name       VARCHAR(100)  NOT NULL,
  local_currency      CHAR(3)       NOT NULL,
  unit_cost           DECIMAL(12,2) NOT NULL,
  unit_selling_price  DECIMAL(12,2) NOT NULL,
  order_quantity      INT           NOT NULL,
  discount_applied    DECIMAL(4,2)  NOT NULL,  -- 0.00 to 0.20
  net_profit          DECIMAL(15,2) NOT NULL   -- can be negative
);

SHOW TABLES;