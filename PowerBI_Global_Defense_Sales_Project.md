# Global Defense Sales Analytics: Power BI Project

**Roles this targets:** Data Analyst · Business Analyst · BI Developer · Sales/Commercial Analyst
**Tools:** Power BI Desktop, Power Query (M), DAX, Star-schema modelling
**Data:** 500,000 orders · Oct 2023 – Sep 2026 · 7 countries · 51 products · 16 suppliers · ~95K customers

---

## 1. Business problem
Leadership needs to know where revenue and profit come from, what is leaking margin, and which regions, products and customer segments to prioritise.

1. How are revenue, profit and margin trending?
2. Which products, suppliers, regions and segments drive profit?
3. How much revenue is lost to returns and cancellations?
4. How do discounts affect profitability?
5. How concentrated is revenue among customers?

---

## 2. Data findings (do this audit in Power Query and mention it in interviews)

| Check | Result | Decision |
|---|---|---|
| Rows / nulls / duplicate Order_ID | 500,000 / none / none | No cleaning of nulls needed |
| `Local_Currency` column | Unit prices are numerically the same across all 7 currencies (e.g. 9mm Ammo ≈ 36 in every currency) | Treat amounts as one common unit; **do not apply FX**. State this as an assumption |
| `Net_Profit` | Exactly `(Price × (1 − Discount) − Cost) × Qty` for Completed and Pending; **0 for Returned and Cancelled** | Profit is only realised on Completed orders |
| Product → Category / Supplier / Cost | Strict 1:1 | Safe to build `Dim_Product` |
| Customer → Country / Segment | Strict 1:1 | Safe to build `Dim_Customer` |
| Ship_Date < Order_Date | 0 rows | Ship days = 1 to 7 |
| Loss-making orders | 20,979 Completed orders have negative profit | Analyse as a discount problem |

---

## 3. Data model (star schema)

```
Dim_Date ──────┐
Dim_Product ───┼──► Fact_Sales
Dim_Customer ──┘
```

- `Fact_Sales[Order_Date]` → `Dim_Date[Date]` (many-to-one, single direction). Mark `Dim_Date` as the date table.
- `Fact_Sales[Product_ID]` → `Dim_Product[Product_ID]`
- `Fact_Sales[Customer_ID]` → `Dim_Customer[Customer_ID]`
- Hide raw columns in the fact table; build measures only in a `_Measures` table.

---

## 4. Power Query (M)

Load the Excel file as `Raw`. Then create the queries below (Reference `Raw`, don't duplicate it).

**Fact_Sales**
```m
let
    Source = Raw,
    Typed = Table.TransformColumnTypes(Source, {
        {"Order_Date", type date}, {"Ship_Date", type date},
        {"Unit_Cost", type number}, {"Unit_Selling_Price", type number},
        {"Order_Quantity", Int64.Type}, {"Discount_Applied", type number},
        {"Net_Profit", type number}}),
    Gross   = Table.AddColumn(Typed, "Gross_Sales", each [Unit_Selling_Price] * [Order_Quantity], type number),
    NetRev  = Table.AddColumn(Gross, "Net_Revenue", each [Gross_Sales] * (1 - [Discount_Applied]), type number),
    Cost    = Table.AddColumn(NetRev, "Total_Cost", each [Unit_Cost] * [Order_Quantity], type number),
    Disc    = Table.AddColumn(Cost, "Discount_Amount", each [Gross_Sales] - [Net_Revenue], type number),
    ShipDays= Table.AddColumn(Disc, "Ship_Days", each Duration.Days([Ship_Date] - [Order_Date]), Int64.Type),
    Band    = Table.AddColumn(ShipDays, "Discount_Band", each
                if [Discount_Applied] = 0 then "0%"
                else if [Discount_Applied] <= 0.05 then "1-5%"
                else if [Discount_Applied] <= 0.10 then "6-10%"
                else if [Discount_Applied] <= 0.15 then "11-15%"
                else "16-20%", type text),
    Keep = Table.SelectColumns(Band, {"Order_ID","Order_Date","Ship_Date","Order_Status","Customer_ID",
        "Product_ID","Unit_Cost","Unit_Selling_Price","Order_Quantity","Discount_Applied","Discount_Band",
        "Gross_Sales","Discount_Amount","Net_Revenue","Total_Cost","Net_Profit","Ship_Days"})
in
    Keep
```

**Dim_Product**
```m
let
    Source = Table.SelectColumns(Raw, {"Product_ID","Product_Name","Product_Category","Supplier_Name"}),
    Dedup  = Table.Distinct(Source, {"Product_ID"})
in
    Dedup
```

**Dim_Customer**
```m
let
    Source = Table.SelectColumns(Raw, {"Customer_ID","Customer_Segment","Customer_Country","Customer_Region"}),
    Dedup  = Table.Distinct(Source, {"Customer_ID"})
in
    Dedup
```

**Dim_Date** (DAX calculated table, with a fiscal year starting in October to match the data)
```dax
Dim_Date =
ADDCOLUMNS(
    CALENDAR(DATE(2023,10,1), DATE(2026,9,30)),
    "Year", YEAR([Date]),
    "Month No", MONTH([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Year-Month", FORMAT([Date], "YYYY-MM"),
    "Quarter", "Q" & QUARTER([Date]),
    "Fiscal Year", "FY" & (YEAR([Date]) + IF(MONTH([Date]) >= 10, 1, 0)),
    "Weekday", FORMAT([Date], "ddd")
)
```

---

## 5. DAX measures

Create an empty table `_Measures` (Enter Data) and add these.

```dax
-- Core
Orders            = DISTINCTCOUNT(Fact_Sales[Order_ID])
Customers         = DISTINCTCOUNT(Fact_Sales[Customer_ID])
Units Sold        = SUM(Fact_Sales[Order_Quantity])

Revenue =                                        -- realised revenue
CALCULATE(SUM(Fact_Sales[Net_Revenue]), Fact_Sales[Order_Status] = "Completed")

Profit =
CALCULATE(SUM(Fact_Sales[Net_Profit]), Fact_Sales[Order_Status] = "Completed")

Cost =
CALCULATE(SUM(Fact_Sales[Total_Cost]), Fact_Sales[Order_Status] = "Completed")

Profit Margin %   = DIVIDE([Profit], [Revenue])
Avg Order Value   = DIVIDE([Revenue], CALCULATE([Orders], Fact_Sales[Order_Status] = "Completed"))
Avg Discount %    = CALCULATE(AVERAGE(Fact_Sales[Discount_Applied]), Fact_Sales[Order_Status] = "Completed")
Avg Ship Days     = AVERAGE(Fact_Sales[Ship_Days])

-- Revenue leakage
Returned Revenue  = CALCULATE(SUM(Fact_Sales[Net_Revenue]), Fact_Sales[Order_Status] = "Returned")
Cancelled Revenue = CALCULATE(SUM(Fact_Sales[Net_Revenue]), Fact_Sales[Order_Status] = "Cancelled")
Pending Revenue   = CALCULATE(SUM(Fact_Sales[Net_Revenue]), Fact_Sales[Order_Status] = "Pending")
Return Rate %     = DIVIDE(CALCULATE([Orders], Fact_Sales[Order_Status] = "Returned"), [Orders])
Cancel Rate %     = DIVIDE(CALCULATE([Orders], Fact_Sales[Order_Status] = "Cancelled"), [Orders])
Revenue Leakage % = DIVIDE([Returned Revenue] + [Cancelled Revenue],
                           CALCULATE(SUM(Fact_Sales[Net_Revenue])))
Loss-Making Orders =
CALCULATE([Orders], Fact_Sales[Order_Status] = "Completed", Fact_Sales[Net_Profit] < 0)

-- Time intelligence
Revenue LY   = CALCULATE([Revenue], SAMEPERIODLASTYEAR(Dim_Date[Date]))
Revenue YoY % = DIVIDE([Revenue] - [Revenue LY], [Revenue LY])
Profit LY    = CALCULATE([Profit], SAMEPERIODLASTYEAR(Dim_Date[Date]))
Profit YoY % = DIVIDE([Profit] - [Profit LY], [Profit LY])
Revenue YTD  = TOTALYTD([Revenue], Dim_Date[Date], "9/30")      -- fiscal year ends 30 Sep
Revenue 3M Avg =
AVERAGEX(DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -3, MONTH), [Revenue])

-- Ranking and concentration
Product Rank = RANKX(ALL(Dim_Product[Product_Name]), [Profit], , DESC)
Revenue Share % = DIVIDE([Revenue], CALCULATE([Revenue], ALL(Dim_Product)))

Customer Revenue Rank =
RANKX(ALL(Dim_Customer[Customer_ID]), [Revenue], , DESC, Dense)
Top 10% Customer Revenue =
VAR _n = ROUNDUP(DISTINCTCOUNT(Dim_Customer[Customer_ID]) * 0.1, 0)
RETURN SUMX(TOPN(_n, ALL(Dim_Customer[Customer_ID]), [Revenue]), [Revenue])

-- Discount what-if (add a parameter 0-20% called 'Discount Cap')
Profit @ Cap =
SUMX(
    FILTER(Fact_Sales, Fact_Sales[Order_Status] = "Completed"),
    (Fact_Sales[Unit_Selling_Price] * (1 - MIN(Fact_Sales[Discount_Applied], 'Discount Cap'[Discount Cap Value]))
        - Fact_Sales[Unit_Cost]) * Fact_Sales[Order_Quantity]
)
```

> Note: `Profit @ Cap` is a simple scenario that assumes the same volume at a lower discount. State that assumption on the page.

---

## 6. Report pages

| # | Page | Visuals |
|---|---|---|
| 1 | **Executive Summary** | KPI cards (Revenue, Profit, Margin %, Orders, Customers, AOV) with YoY; monthly revenue and profit line; revenue by region (map); category donut |
| 2 | **Product & Supplier** | Top 10 products by profit (bar); category × region matrix with conditional formatting; supplier ranking table; Pareto of products |
| 3 | **Customers & Geography** | Segment revenue and margin; country comparison; top-10% customer concentration card; decomposition tree (Region → Country → Segment) |
| 4 | **Discount & Profitability** | Margin % by discount band (column); loss-making orders by category; scatter of discount vs margin; **what-if slider** for the discount cap |
| 5 | **Fulfilment & Leakage** | Order status funnel; returned/cancelled revenue by month; ship-days distribution; return rate by region and category |

**Design tips:** one dark navy theme with one accent colour; slicers for Fiscal Year, Region, Segment, Category (synced across pages); bookmarks for a page-navigation bar; tooltips pages for top products; Row-level security by Region as a bonus (`[Customer_Region] = USERPRINCIPALNAME()` mapping).

**Performance:** 500K rows is fine in Import mode. Turn off Auto date/time, remove unused columns, and use the star schema above.

---

## 7. Key insights (verified on the data)

Realised figures are Completed orders only, in the dataset's common currency unit.

1. **Realised revenue ≈ 173.4B, profit ≈ 28.1B, margin ≈ 16.2%** across 400K completed orders (80% of all orders).
2. **Discounting is the main margin lever.** Margin falls from **24.7% (no discount)** to **22.2% (1–5%)**, **17.9% (6–10%)**, **13.3% (11–15%)** and **8.0% (16–20%)**. About **21K completed orders (5.2%) lost money**. Every one had a discount of 14% or more applied to an order with only a 15–25% markup over cost, and none occurred at discounts of 10% or below. About 20% of orders discounted above 15% were loss-making.
3. **Revenue leakage is 15%.** 10% of orders (≈21.8B) were returned and 5% (≈11.0B) cancelled, and another 5% (≈10.8B) are still pending. Return rates are flat (~10%) across categories and regions, so the cause is process-wide, not a single problem product or market.
4. **Ammunition is ~77% of revenue** (≈133.5B of 173.4B) and ~77% of profit (≈21.6B), driven by very large order quantities rather than price. Armor is a distant second (≈17.8B).
5. **APAC is the largest region** (≈74.2B revenue, 43%), led by India (≈39.1B). The USA is the largest single country (≈41.0B).
6. **Customer concentration:** the top 10% of customers generate **~46%** of realised revenue.
7. **Segments:** Law Enforcement/Defense (≈75.7B) and Military/Army (≈65.1B) make up ~81% of revenue. Personal Use is only ~3%.
8. **Supplier concentration:** the top two suppliers (Companhia Brasileira de Cartuchos, Naraindas Deepchand & Sons) supply ≈71% of revenue, a supply-risk talking point.
9. **Flat growth:** FY2024, FY2025 and FY2026 (Oct–Sep) revenue is ≈58.0B, 57.3B and 58.1B, so there is no real growth. Margin stays ~16% in every segment, region and category, so profit is driven by volume mix and discount, not pricing.

### Recommendations to present
- Cap discounts at ~10% and require approval above that. Use the what-if page to quantify the gain.
- Investigate the returns/cancellation process (order accuracy, delivery, documentation) because the rate is uniform.
- Diversify supply for ammunition, and grow non-ammunition categories where volume per order is low.
- Run a key-account programme for the top 10% of customers.

> **Honesty note for interviews:** this dataset looks synthetic (margins, return rates and discounts are almost uniform across every dimension, and the currency column does not change prices). Say this openly, along with how you handled it. Recruiters value that more than inflated claims.

---

## 8. Resume content

**Project title:** Global Defense Sales Analytics Dashboard | Power BI, DAX, Power Query

**Bullets (pick 3–4):**
- Built a 5-page Power BI report on **500K orders / 173B realised revenue**, with a star-schema model, Power Query transformations and 30+ DAX measures (YoY, YTD, rolling average, ranking).
- Audited the data (currency, profit logic, key integrity) and documented assumptions, which prevented incorrect FX conversion and profit double-counting.
- Identified that margin drops from **24.7% to 8.0%** as discounts rise from 0% to 20%, and that **~21K orders were loss-making**. Built a what-if discount-cap model to quantify the impact.
- Quantified **15% revenue leakage** from returns and cancellations (~32.8B) and **top-10% customer concentration of 46%**, then recommended discount governance and key-account management.
- Delivered KPI, product, customer, discount and fulfilment views with synced slicers, drill-through, bookmarks and tooltip pages for executive use.

**Skills line:** Power BI · DAX · Power Query (M) · Data Modelling (Star Schema) · KPI Design · Sales & Margin Analysis · Data Storytelling

**Interview prompts to prepare**
- Why did you filter profit and revenue to Completed orders?
- Why didn't you convert currencies? How did you verify that?
- How would you extend this with a forecast or customer segmentation (RFM)?
- Difference between a calculated column and a measure, and why you used each.

---

## 9. Publishing checklist
1. Build in Power BI Desktop, then publish to Power BI Service.
2. Export 5 page screenshots + a 60–90 sec screen recording.
3. Put the `.pbix`, screenshots, this README, and a short case-study write-up on GitHub, and link it on your resume and LinkedIn.
