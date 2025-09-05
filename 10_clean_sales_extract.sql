-- sql/10_clean_sales_extract.sql
-- Idempotent extract to feed Power BI
WITH base AS (
  SELECT
      s.OrderID,
      s.CustomerID,
      s.ProductID,
      CAST(s.OrderDate AS DATE) AS OrderDate,
      s.Quantity,
      s.PricePerUnit,
      s.DiscountValue,
      s.PromotionID
  FROM stg_Sales s
  WHERE s.OrderDate BETWEEN DATEFROMPARTS(2020,1,1) AND DATEFROMPARTS(2024,12,31)
)
SELECT
  b.*,
  (b.Quantity * b.PricePerUnit)                                AS [Total Sales],
  (b.Quantity * b.PricePerUnit - COALESCE(b.DiscountValue,0))  AS [Net Sales]
FROM base b;
