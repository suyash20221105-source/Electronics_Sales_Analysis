# Electronics Sales Analytics (Power BI)

End‑to‑end data analytics and visualization project for an electronics company.  
This repository documents the complete pipeline I used — from **data loading** and **SQL filtering**, through **Power Query** cleanup and **DAX measures**, to **validation** and **dashboarding** in Power BI.

> **Tools:** Power BI Desktop (2024+), Power Query (M), SQL (any ANSI‑SQL engine), Excel (for validation).

---

## 📂 Repository Structure
```
Electronics-Sales-Analytics-PowerBI/
├─ README.md
├─ electronics-sales-analytics.pbix                 # (optional) add your PBIX here
├─ assets/
│  └─ screenshots/
│     ├─ 01-raw-table.png
│     ├─ 02-comparison.png
│     ├─ 03-top-bottom.png
│     └─ 04-overview.png
├─ sql/
│  ├─ 00_schema_and_staging.sql
│  └─ 10_clean_sales_extract.sql
├─ powerquery/
│  └─ Sales_Query_M_Code.m
├─ dax/
│  └─ measures.md
└─ validation/
   └─ data_validation_checklist.md
```

---

## 1) Business Goal
Provide a trusted, performant sales analytics layer and dashboards for:
- Sales, Profit, Quantity and Orders KPIs
- Top/Bottom products and promotional effectiveness
- Geo sales by city, time trends and profit vs. net sales correlation
- Side‑by‑side period comparisons using date slicers

---

## 2) Data Loading
1. **Sources**: `Sales`, `Products`, `Customers`, `Promotions`, `Cities` tables (CSV or DB).  
2. **Model grain**: one row = one order line (OrderID × ProductID).  
3. Load raw tables to **Power BI**; disable *Auto Date/Time* for performance.

**Raw snapshot:**  
![Raw table](assets/screenshots/01-raw-table.png)

---

## 3) SQL Filtering & Lightweight Shaping
I used SQL to push filters/calculations down to the source for speed and reproducibility.

```sql
-- sql/10_clean_sales_extract.sql
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
  FROM dbo.Sales s
  WHERE s.OrderDate BETWEEN DATEFROMPARTS(2020,1,1) AND DATEFROMPARTS(2024,12,31)
)
SELECT
  b.*,
  (b.Quantity * b.PricePerUnit)                        AS [Total Sales],
  (b.Quantity * b.PricePerUnit - COALESCE(b.DiscountValue,0)) AS [Net Sales]
FROM base b;
```

> Keep SQL **idempotent** and **versioned** in `/sql` so the extract is 100% reproducible.

---

## 4) Power Query (M) – Data Types & Column Corrections
Key steps in the **Sales** query (full M in `powerquery/Sales_Query_M_Code.m`):

```m
// powerquery/Sales_Query_M_Code.m (excerpt)
let
  Source = Excel.Workbook(File.Contents("data/Sales.xlsx"), null, true){[Name="Sales"]}[Content],
  Trimmed = Table.TransformColumns(Source, {{ "Customer Name", Text.Trim, type text }, { "Product Name", Text.Trim, type text }}),
  Typed = Table.TransformColumnTypes(Trimmed, {
      {"OrderID", Int64.Type},
      {"CustomerID", Int64.Type},
      {"ProductID", Int64.Type},
      {"OrderDate", type date},
      {"Quantity", Int64.Type},
      {"Price Per Unit", Currency.Type},
      {"Discount Value", Currency.Type},
      {"PromotionID", type text}
  }),
  ReplacedNulls = Table.ReplaceValue(Typed, null, 0, Replacer.ReplaceValue, {"Discount Value"}),
  AddedTotalSales = Table.AddColumn(ReplacedNulls, "Total Sales", each [Quantity] * [#"Price Per Unit"], Currency.Type),
  AddedNetSales = Table.AddColumn(AddedTotalSales, "Net Sales", each [Total Sales] - [#"Discount Value"], Currency.Type),
  RemovedErrors = Table.RemoveRowsWithErrors(AddedNetSales)
in
  RemovedErrors
```

Other PQ tasks:
- Build **dimensions** (`Products`, `Customers`, `Promotions`, `City`) using *Remove Duplicates*.
- Generate a **Date** table in DAX (see below) or in PQ; mark as Date table.
- Ensure clean relationships in **star schema** (one-to-many from dimensions to Sales).

---

## 5) Measures Table & DAX (fast, reusable analytics)
Create an empty table to host measures:

```DAX
-- dax/measures.md (excerpt)
Measures = SELECTCOLUMNS ( { (1) }, "Dummy", 1 )
```

**Core Measures**
```DAX
Net Sales       = SUM ( Sales[Net Sales] )
Total Sales     = SUM ( Sales[Total Sales] )
Total Profit    = SUM ( Sales[Profit] )
Quantity Sold   = SUM ( Sales[Quantity] )
Orders Count    = DISTINCTCOUNT ( Sales[OrderID] )

Discount %      = DIVIDE ( SUM ( Sales[Discount Value] ), [Total Sales] )
Profit Margin % = DIVIDE ( [Total Profit], [Net Sales] )
```

**Date Intelligence** (requires a marked date table):
```DAX
Date = ADDCOLUMNS (
    CALENDAR ( DATE(2020,1,1), DATE(2024,12,31) ),
    "Year",  YEAR([Date]),
    "MonthNo", MONTH([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Quarter", "Q" & FORMAT([Date], "Q")
)

Net Sales LY = CALCULATE ( [Net Sales], DATEADD ( 'Date'[Date], -1, YEAR ) )
YoY Net Sales % = DIVIDE ( [Net Sales] - [Net Sales LY], [Net Sales LY] )
```

**Top/Bottom & Ranking**
```DAX
Product Rank by Sales = RANKX ( ALL ( Products[Product Name] ), [Net Sales], , DESC, Dense )
Top N Selector = SELECTEDVALUE ( 'Parameters'[Top N], 5 )
```

> Using **measure branching**, one calculation feeds others, improving both speed and maintainability.

---

## 6) Data Validation (Metrics + Excel Pivot)
Quality checks before publishing:

**Metrics (in PBIX)**
- Row Count parity: source vs. model
- Totals match: `SUM(Net Sales)`, `SUM(Quantity)`, `Orders Count`
- Null rates: `Discount Value`, `PromotionID`
- Relationship integrity: No orphan keys (Products, Customers, City)

**Excel Pivot Cross‑check**
1. Export `Sales` (or use the same CSV as the model).  
2. Insert PivotTable → Rows: `Year`, `Product Name`; Values: `Sum of Net Sales`, `Sum of Profit`, `Sum of Quantity`.  
3. Grand totals should match PBIX measures within ≤ 0.1%. Record variances in `validation/data_validation_checklist.md`.

---

## 7) Building the Dashboards (step‑by‑step)

### A) Comparison Cards (Sales/Profit/Quantity)
- Visual: Clustered columns; pair two measures (`[Net Sales]` vs `[Net Sales LY]`) with **date slicers**.  
![Comparison](assets/screenshots/02-comparison.png)

### B) Top/Bottom Product Analysis
- Visuals: Top 5 / Bottom 5 bar charts driven by `Product Rank by Sales/Profit/Quantity`.  
![Top Bottom](assets/screenshots/03-top-bottom.png)

### C) Overview (Geo, Orders KPI, Promotions, Correlation, Trend)
- *Sales by City* map (City dimension → `Lat`, `Long`).  
- KPI card: `[Orders Count]`.  
- Promotions bar: Avg discount by category.  
- Scatter: `Profit` vs `Net Sales` to show linearity.  
- Trend: Area/line chart of `[Net Sales]` over time.  
![Overview](assets/screenshots/04-overview.png)

---

## 8) Performance & Modeling Notes
- Star schema with single‑direction relationships from dimensions to `Sales`.
- Disable Auto Date/Time; use one **official Date** table.
- Hide numeric base columns and expose only **measures** to report users.
- Prefer *DAX measures* over calculated columns when possible.
- Use **SQL filters** for heavy reductions (date range, excluded promotions).

---

## 9) How to Reproduce
1. Clone the repo and place your raw files under `data/` (or point to DB in PQ).
2. Open `electronics-sales-analytics.pbix` (add yours) and refresh.
3. Validate with `validation/data_validation_checklist.md`.
4. Explore dashboard pages: *Overview*, *Top/Bottom*, *Comparisons*, *Raw Table*.

---

## 10) License & Credits
MIT licensed; feel free to fork and adapt. Screenshots are generated from my Power BI report.
