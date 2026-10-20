USE global_defense_sales;

TRUNCATE TABLE sales_data;   -- agar dobara load karo to duplicate na ho

LOAD DATA LOCAL INFILE 'D:/download/Global_Defense_Sales_Data_500K/sales.csv'
INTO TABLE sales_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) AS total_rows FROM sales_data;   -- 500000 aana chahiye