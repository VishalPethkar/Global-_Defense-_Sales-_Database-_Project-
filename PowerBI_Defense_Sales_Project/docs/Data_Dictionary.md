# Data Dictionary

Source: `Global_Defense_Sales_Data_500K.xlsx`, sheet `Sales_Data` (500,000 rows × 18 columns, one row per order).

## Fact_Sales (grain: one row per order)
| Column | Type | Source | Description |
|---|---|---|---|
| Order_ID | text | raw | Unique order key (e.g. ORD-2023-798361) |
| Order_Date | date | raw | Relationship to `Dim_Date` (active) |
| Ship_Date | date | raw | Relationship to `Dim_Date` (inactive; use `USERELATIONSHIP`) |
| Order_Status | text | raw | Completed (80%), Returned (10%), Cancelled (5%), Pending (5%) |
| Customer_ID | text | raw | FK → `Dim_Customer` |
| Product_ID | text | raw | FK → `Dim_Product` |
| Unit_Cost | number | raw | Cost per unit |
| Unit_Selling_Price | number | raw | List price per unit (before discount) |
| Order_Quantity | int | raw | Units in the order |
| Discount_Applied | number | raw (rounded to 2 dp) | 0.00–0.20 |
| Discount_Band | text | derived | 0%, 1-5%, 6-10%, 11-15%, 16-20% → `Dim_DiscountBand` |
| Gross_Sales | number | derived | `Unit_Selling_Price × Order_Quantity` |
| Discount_Amount | number | derived | `Gross_Sales − Net_Revenue` |
| Net_Revenue | number | derived | `Gross_Sales × (1 − Discount_Applied)` |
| Total_Cost | number | derived | `Unit_Cost × Order_Quantity` |
| Net_Profit | number | raw | `Net_Revenue − Total_Cost` for Completed/Pending; **0** for Returned/Cancelled |
| Ship_Days | int | derived | `Ship_Date − Order_Date` (1–7) |
| Is_Loss_Making | int | derived | 1 if Completed **and** `Net_Profit < 0` |

## Dim_Product (51 rows)
`Product_ID` (PK) · `Product_Name` · `Product_Category` (8) · `Supplier_Name` · `Supplier_Short` · `Supplier_Country` (parsed; "AWEIL India" → India) · `Product_Group` (Ammunition / Non-Ammunition)

## Dim_Customer (94,918 rows)
`Customer_ID` (PK) · `Customer_Segment` (4) · `Customer_Country` (7) · `Customer_Region` (4) · `Local_Currency` (reference only) · **RFM snapshot (static, as of 1 Oct 2026, Completed orders):** `Recency_Days` · `Order_Count` · `Lifetime_Revenue` · `R_Score` · `F_Score` · `M_Score` · `RFM_Segment`. The 3,499 customers with no completed order are labelled `No Completed Orders`.

## Dim_Date (1,096 rows, 1 Oct 2023 – 30 Sep 2026)
`Date` (PK) · `Year` · `Month_No` · `Month` · `Year_Month` · `Quarter` · `Fiscal_Year` (FY starts 1 Oct; FY2024 = Oct-23 → Sep-24) · `Fiscal_Month_No` · `Fiscal_Quarter` · `Weekday` · `Weekday_No` · `Is_Weekend`

## Dim_OrderStatus / Dim_DiscountBand
Small lookup tables that add sort order and grouping (Realised / Pipeline / Leakage; band lower/upper bounds).

## RFM scoring rules
| Score | Recency (days since last order) | Frequency (completed orders) | Monetary (lifetime revenue) |
|---|---|---|---|
| 5 | ≤ 90 | 6+ | top quintile |
| 4 | ≤ 180 | 4–5 | 4th quintile |
| 3 | ≤ 365 | 3 | 3rd quintile |
| 2 | ≤ 540 | 2 | 2nd quintile |
| 1 | > 540 | 1 | bottom quintile |

| Segment | Rule (evaluated in this order) | Customers | Revenue share |
|---|---|---|---|
| Champions | R ≥ 4 and F ≥ 4 | 24,851 | 56.6% |
| High-Value At Risk | R ≤ 2, F ≥ 3, M ≥ 4 | 3,863 | 7.1% |
| At Risk | R ≤ 2 and F ≥ 3 | 4,895 | 1.4% |
| Loyal | F ≥ 3 | 19,718 | 20.3% |
| New / Recent | R ≥ 4 | 9,146 | 3.9% |
| Promising | R = 3 | 7,998 | 3.3% |
| Hibernating | everything else | 20,948 | 7.4% |

## Key definitions
- **Realised** = `Order_Status = "Completed"`. All revenue/profit/margin KPIs use this.
- **Leakage** = Returned + Cancelled order value ÷ value of all orders.
- **Pipeline** = Pending orders (not yet realised).
- **Loss-making order** = Completed order with negative `Net_Profit`.
- **Weighted discount %** = total discount amount ÷ total gross sales.
- **HHI** = Σ(supplier revenue share)² × 10,000.
