# Data Validation Checklist

## Row & Totals
- [ ] Row count (source vs model) matches
- [ ] Sum(Net Sales) matches source within ≤ 0.1%
- [ ] Sum(Quantity) matches source within ≤ 0.1%
- [ ] Orders Count matches

## Nulls & Keys
- [ ] Null rate of Discount Value documented
- [ ] No orphan ProductID/CustomerID/PromotionID/City keys after relationships

## Excel Pivot Cross-check
Create Pivot with Rows: Year, Product Name; Values: Sum(Net Sales), Sum(Profit), Sum(Quantity).  
Record variances:

| Metric | Source | PBIX | Variance |
|---|---:|---:|---:|
| Net Sales | | | |
| Profit | | | |
| Quantity | | | |
| Orders Count | | | |

