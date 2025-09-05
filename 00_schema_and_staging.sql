-- sql/00_schema_and_staging.sql
-- Create staging views/tables for Sales analytics (adjust schema names to your DB)
CREATE VIEW stg_Sales AS
SELECT * FROM dbo.Sales;  -- replace with your actual source
CREATE VIEW stg_Products AS
SELECT * FROM dbo.Products;
CREATE VIEW stg_Customers AS
SELECT * FROM dbo.Customers;
CREATE VIEW stg_Promotions AS
SELECT * FROM dbo.Promotions;
CREATE VIEW stg_Cities AS
SELECT * FROM dbo.Cities;
