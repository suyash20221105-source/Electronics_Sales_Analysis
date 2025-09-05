// dax/measures.md
# Measures (copy into Power BI as measures in a Measures table)

Measures = SELECTCOLUMNS ( { (1) }, "Dummy", 1 )

Net Sales       = SUM ( Sales[Net Sales] )
Total Sales     = SUM ( Sales[Total Sales] )
Total Profit    = SUM ( Sales[Profit] )
Quantity Sold   = SUM ( Sales[Quantity] )
Orders Count    = DISTINCTCOUNT ( Sales[OrderID] )

Discount %      = DIVIDE ( SUM ( Sales[Discount Value] ), [Total Sales] )
Profit Margin % = DIVIDE ( [Total Profit], [Net Sales] )

Date = ADDCOLUMNS (
    CALENDAR ( DATE(2020,1,1), DATE(2024,12,31) ),
    "Year",  YEAR([Date]),
    "MonthNo", MONTH([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Quarter", "Q" & FORMAT([Date], "Q")
)

Net Sales LY = CALCULATE ( [Net Sales], DATEADD ( 'Date'[Date], -1, YEAR ) )
YoY Net Sales % = DIVIDE ( [Net Sales] - [Net Sales LY], [Net Sales LY] )

Product Rank by Sales = RANKX ( ALL ( Products[Product Name] ), [Net Sales], , DESC, Dense )
Product Rank by Profit = RANKX ( ALL ( Products[Product Name] ), [Total Profit], , DESC, Dense )
Product Rank by Quantity = RANKX ( ALL ( Products[Product Name] ), [Quantity Sold], , DESC, Dense )
