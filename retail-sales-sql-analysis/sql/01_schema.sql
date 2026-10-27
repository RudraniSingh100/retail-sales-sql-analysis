-- MySQL 8 schema for the retail sales analysis project
CREATE DATABASE IF NOT EXISTS retail_analysis;
USE retail_analysis;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    region        VARCHAR(20) NOT NULL,
    segment       VARCHAR(20) NOT NULL,
    signup_date   DATE NOT NULL
);

CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    product_name VARCHAR(80) NOT NULL,
    category     VARCHAR(30) NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL,
    unit_cost    DECIMAL(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id    INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date  DATE NOT NULL,
    order_month CHAR(7) NOT NULL,          -- 'YYYY-MM', precomputed to keep queries portable
    channel     VARCHAR(10) NOT NULL,
    discount    DECIMAL(3,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id    INT PRIMARY KEY,
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);
