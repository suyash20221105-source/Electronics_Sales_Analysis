// powerquery/Sales_Query_M_Code.m
let
  Source = Excel.Workbook(File.Contents("data/Sales.xlsx"), null, true){[Name="Sales"]}[Content],
  Trimmed = Table.TransformColumns(Source, {
      {"Customer Name", each Text.Trim(_), type text},
      {"Product Name", each Text.Trim(_), type text},
      {"City", each Text.Proper(Text.Trim(_)), type text}
  }),
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
