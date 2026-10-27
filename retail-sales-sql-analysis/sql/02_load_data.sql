-- Load the CSVs into MySQL (run from the project root; may need --local-infile=1)
USE retail_analysis;

LOAD DATA LOCAL INFILE 'data/customers.csv'   INTO TABLE customers   FIELDS TERMINATED BY ',' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/products.csv'    INTO TABLE products    FIELDS TERMINATED BY ',' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/orders.csv'      INTO TABLE orders      FIELDS TERMINATED BY ',' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/order_items.csv' INTO TABLE order_items FIELDS TERMINATED BY ',' IGNORE 1 LINES;
