USE global_defense_sales;

ALTER TABLE sales_data ADD PRIMARY KEY (order_id);

CREATE INDEX idx_order_date  ON sales_data (order_date);

CREATE INDEX idx_customer    ON sales_data (customer_id);

CREATE INDEX idx_product     ON sales_data (product_id);

CREATE INDEX idx_category    ON sales_data (product_category);

CREATE INDEX idx_region      ON sales_data (customer_region);

CREATE INDEX idx_status      ON sales_data (order_status);