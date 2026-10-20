# Build Guide: from files to a finished Power BI report

Work through the phases in order. Each phase ends with a **checkpoint** so you know it is correct before moving on. Estimated time: 10–14 hours for the whole report.

---

## Phase 0: Settings (5 min)
- File > Options > Current File > Data Load: **turn off "Auto date/time"**, turn off "Time intelligence". (We use our own `Dim_Date`; auto date creates hidden tables per date column and bloats the model.)
- Options > Report settings: leave defaults. Save as `Defense_Sales.pbix`.

## Phase 1: Load and transform (Power Query)
1. Home > Manage Parameters > **New**: `FilePath` (Text).
2. Get Data > Excel > select the workbook > load sheet `Sales_Data`; or paste `powerquery/00_Parameters_and_Raw.pq` into a Blank Query named **Raw**. Untick *Enable load* on `Raw`.
3. Create blank queries and paste, in order: `Fact_Sales`, `Dim_Product`, `Customer_RFM` (untick *Enable load*), `Dim_Customer`.
4. Rename query steps if you like, but **keep the names** `Fact_Sales`, `Dim_Product`, `Dim_Customer`.
5. Close & Apply.

**Checkpoint:** `Fact_Sales` = 500,000 rows, 18 columns · `Dim_Product` = 51 rows · `Dim_Customer` = 94,918 rows · No errors in column quality bars (check "Column profiling based on entire data set").

> Interview line: *"I referenced a single raw staging query, so the source is read once; dimensions are deduplicated on their key after I proved the 1:1 relationships."*

## Phase 2: Model
1. Create the calculated tables from `dax/00_Tables_and_Parameters.dax`: `Dim_Date`, `Dim_OrderStatus`, `Dim_DiscountBand`, `Discount Cap`, `Attrition`.
2. Model view, create relationships (all **Many-to-one, Single direction**, dimension → fact):

| From (fact) | To (dimension) | Active |
|---|---|---|
| `Fact_Sales[Order_Date]` | `Dim_Date[Date]` | **Yes** |
| `Fact_Sales[Ship_Date]` | `Dim_Date[Date]` | **No** (role-playing) |
| `Fact_Sales[Product_ID]` | `Dim_Product[Product_ID]` | Yes |
| `Fact_Sales[Customer_ID]` | `Dim_Customer[Customer_ID]` | Yes |
| `Fact_Sales[Order_Status]` | `Dim_OrderStatus[Order_Status]` | Yes |
| `Fact_Sales[Discount_Band]` | `Dim_DiscountBand[Discount_Band]` | Yes |

3. `Dim_Date`: Table tools > **Mark as date table** > `Date`. Sort `Month` by `Month_No`, `Weekday` by `Weekday_No`.
4. Sort `Dim_OrderStatus[Order_Status]` by `Status_Sort`; `Dim_DiscountBand[Discount_Band]` by `Band_Sort`.
5. Enter Data > empty table `_Measures`. Move the `Discount Cap Value` and `Attrition Value` measures into it. Paste all measures from `dax/01_Measures.dax`; set **display folders** from the section headers; set formats (below).
6. **Hide** in Report view: all raw numeric columns on `Fact_Sales` (keep only keys hidden too), `Dim_*` key columns, helper sort columns.
7. Lay the model out as a star: `Fact_Sales` in the centre, dimensions around it, `_Measures` and parameter tables to the side.

**Measure formats**

| Measure type | Format |
|---|---|
| Revenue, Profit, Cost, Pending/Returned/Cancelled Revenue, Leakage | Currency-free, display units **Billions**, 2 decimals |
| Margin %, Return/Cancel Rate %, Leakage %, shares, YoY % | Percentage, 1 decimal |
| Orders, Customers, Units | Whole number with thousands separator |
| Avg Order Value | Display units Thousands, 0 decimals |

**Checkpoint:** Build a temporary table visual and compare to `validation/expected_values.csv`: Revenue 173.44B · Profit 28.06B · Margin 16.18% · Completed Orders 400,000 · Loss-Making Orders 20,979. All must match (revenue/profit within rounding).

## Phase 3: Theme and layout rules
- View > Themes > Browse > `theme/DefenseNavy_Theme.json`.
- Canvas **1280 × 720** (Page format > Type: Custom). Grid: 24 px outer margin, 12 px gutters.
- Header band y = 0–64: page title (left), slicers or "Data as of" (right).
- One accent colour (amber `#F5A623`) for the *thing you want read first*; blue/teal for context; red only for bad.
- **Every visual title is a finding**, not a label ("Margin falls from 24.7% to 8.0% as discounts rise"). Use dynamic titles where a measure exists.
- Slicers (sync across pages via View > Sync slicers): `Dim_Date[Fiscal_Year]`, `Dim_Customer[Customer_Region]`, `Dim_Customer[Customer_Segment]`, `Dim_Product[Product_Category]`.
- Accessibility: alt text on every visual, tab order set, ≥ 4.5:1 contrast, never colour-only meaning.

## Phase 4: Pages

### Page 0 · Home
Title, one-sentence purpose, "Data as of" card (`[Data As Of]`), 6 navigation buttons (Page navigator visual, or shapes + page-navigation actions), and a short "How to read" note (realised = Completed orders).

### Page 1 · Executive Summary
| Zone (x, y, w, h) | Visual | Fields |
|---|---|---|
| (24, 76, 1232, 96) | 6 × **Card (new)** or KPI cards | Revenue · Profit · Profit Margin % · Completed Orders · Active Customers · Avg Order Value. Reference label: `[Revenue YoY Label]` coloured with `[YoY Colour]` |
| (24, 184, 760, 280) | **Line + clustered column** | X: `Dim_Date[Year_Month]`; columns `[Revenue]`, line `[Profit Margin %]` (secondary axis); add `[Revenue 3M Avg]` as a second line |
| (796, 184, 460, 280) | **Filled map / Map** | Location `Customer_Country`, size `[Revenue]`, tooltip `[Profit Margin %]` |
| (24, 476, 400, 220) | **Donut** | Legend `Product_Category`, values `[Revenue]` (top 3 + other via Top N) |
| (436, 476, 400, 220) | **Clustered bar** | `Customer_Segment` by `[Revenue]` |
| (848, 476, 408, 220) | **Smart narrative** or text box | Key takeaways (edit the auto text) |

Finding titles to use: "Flat growth: FY26 revenue is 1.3% above FY25" · "APAC contributes 43% of realised revenue".

### Page 2 · Product & Supplier
| Visual | Fields / setup |
|---|---|
| **Bar: Top 10 products by profit** | Axis `Product_Name`, value `[Profit]`; Filters: Top N 10 by `[Profit]` |
| **Pareto** (line + column) | Axis `Product_Name` sorted by `[Profit]` desc; column `[Profit]`; line `[Cumulative Profit % (Pareto)]`; add a constant line at 80% |
| **Matrix: Category × Region** | Rows `Product_Category`, columns `Customer_Region`, values `[Revenue]`; conditional formatting (data bars or colour scale) |
| **Table: Supplier ranking** | `Supplier_Short`, `Supplier_Country`, `[Revenue]`, `[Supplier Share %]`, `[Profit Margin %]`; data bars on share |
| **Card** | `[Supplier HHI]` with a note "> 2,500 = highly concentrated" |
| **Tooltip page** | Hidden page 320×240, `Page information > Allow use as tooltip`, field `Product_Name`; show `[Revenue]`, `[Profit]`, `[Profit Margin %]`, a mini column by `Fiscal_Year`. Assign it on the bar and Pareto visuals |
| **Drill-through** | Hidden page `Product Detail` with drill-through field `Product_Name` |

### Page 3 · Customers & Geography
| Visual | Fields / setup |
|---|---|
| Clustered column by segment | `Customer_Segment`, `[Revenue]`, line `[Profit Margin %]` |
| Country comparison (bar) | `Customer_Country`, `[Revenue]`, sorted desc, colour by `Customer_Region` |
| Card | `[Top 10% Customer Share %]`, subtitle "of customers hold this share of revenue" |
| **Decomposition tree** | Analyse `[Revenue]`; explain by `Customer_Region` → `Customer_Country` → `Customer_Segment` |
| Table: Top 15 customers | `Customer_ID`, `Customer_Segment`, `Customer_Country`, `[Revenue]`, `[Completed Orders]`; Top N 15; **drill-through target** page `Customer Detail` |
| Cards | `[Repeat Customer %]`, `[Revenue per Customer]` |

### Page 4 · Discount & Profitability (the "money" page)
| Visual | Fields / setup |
|---|---|
| **Column: margin by discount band** | Axis `Dim_DiscountBand[Discount_Band]`, value `[Profit Margin %]`; conditional colour with `[Margin Colour]`. Title: "Margin falls from 24.7% to 8.0% as discounts rise" |
| **Column: loss-making orders by category** | Axis `Product_Category`, value `[Loss-Making Orders]` |
| **Scatter** | Each point = a product; X `[Weighted Discount %]`, Y `[Profit Margin %]`, size `[Revenue]` |
| **Slicer: Discount Cap** | `'Discount Cap'[Discount Cap]` (slider style) |
| **Slicer: Attrition** | `Attrition[Attrition]` (slider style) |
| **Cards (what-if result)** | `[Profit]` (actual) · `[Profit @ Cap (After Attrition)]` · `[Profit Uplift]` · `[Profit Uplift %]` · `[Orders Affected by Cap]` · `[Break-even Attrition %]` |
| **Dynamic title** | `[Discount Page Title]` |
| **Footnote text box** | `[Assumption Note]` |

Sanity test: cap = 10%, attrition = 0% → uplift **+5.05B (+18.0%)**, affected orders **190,570**, break-even **37.9%**. Cap = 20% → uplift 0.

### Page 5 · Fulfilment & Leakage
| Visual | Fields / setup |
|---|---|
| **Funnel / bar by status** | Axis `Dim_OrderStatus[Order_Status]`, value `[Orders (All)]` (and `[Order Value (All Statuses)]` in a second visual). *Do not* use `[Revenue]` here: it is Completed-only and shows blank for other statuses. |
| Column by month | `Year_Month`, stacked `[Returned Revenue]` + `[Cancelled Revenue]` |
| Histogram-style column | `Fact_Sales[Ship_Days]` (as category) by `[Orders (All)]` |
| **Matrix heatmap** | Rows `Product_Category`, columns `Customer_Region`, values `[Return Rate %]`, colour scale. The point is that it is *uniformly ~10%* |
| Cards | `[Revenue Leakage %]`, `[Leakage Revenue]`, `[Est. Profit Forgone to Leakage]`, `[Pending Revenue]` |

### Page 6 · Customer Segmentation (RFM)
| Visual | Fields / setup |
|---|---|
| Bar: customers per segment | `Dim_Customer[RFM_Segment]`, `[RFM Customers]` (filter out "No Completed Orders") |
| Bar: revenue per segment | `RFM_Segment`, `[Revenue]` |
| Scatter | X `Recency_Days`, Y `Order_Count`, size `Lifetime_Revenue`, legend `RFM_Segment` |
| Cards | `[At-Risk Revenue Exposure]`, `[Avg Recency (Days)]`, `[Avg Orders per Customer]` |
| Table (action list) | Filter `RFM_Segment` = "High-Value At Risk": `Customer_ID`, `Customer_Country`, `Lifetime_Revenue`, `Recency_Days` |
| Text box | RFM scoring rules (see `docs/Data_Dictionary.md`) |

### Page 7 · About & Data Notes
Definitions of realised/leakage, the five audit decisions, the synthetic-data statement, the no-FX assumption, the what-if limitations, data source and refresh date.

## Phase 5: Interactivity polish
- **Bookmarks:** "Reset filters" and one per page for the navigation bar; set *Data* off, *Display* on for navigation bookmarks so they don't reset slicers.
- **Edit interactions:** stop the KPI cards from filtering the map; stop slicers from changing the what-if cards where not relevant.
- **Field parameter:** use `Metric Selector` in the Page 1 trend chart so viewers can switch between Revenue/Profit/Margin/Orders.
- **Conditional formatting** on matrices/tables using `[Margin Colour]`.
- **Row-level security** (View > Manage roles):
  - Simple: role `APAC` with filter `Dim_Customer[Customer_Region] = "APAC"` (one role per region).
  - Scalable: add a `UserRegion` table (`Email`, `Region`) and filter `Dim_Customer[Customer_Region] = LOOKUPVALUE(UserRegion[Region], UserRegion[Email], USERPRINCIPALNAME())`.
  - Test with View as.

## Phase 6: Validate
1. Reconcile every row of `validation/expected_values.csv` against a table visual (slice by the Filter_Context where needed).
2. Spot-check 3 random orders: compare `Net_Revenue`, `Net_Profit` to the formula.
3. Run **Performance Analyzer** on every page; no visual should exceed ~1 s. The usual culprits are `Top 10% Customer Revenue` (iterates ~91K customers) and the RFM table, so keep them off the same page as many other visuals.
4. Check **tab order, alt text, and mobile layout** (View > Mobile layout) for the Executive page.

## Phase 7: Performance and size
- Import mode; 500K rows is comfortable (a compact model; check the .pbix size when you save).
- Remove unused columns in Power Query (already done); round to 2 dp (done); disable Auto date/time (done).
- Optional "big level" extension: parametrise `RangeStart`/`RangeEnd` and configure **incremental refresh** on `Fact_Sales`, and describe it as the production pattern for a growing fact table.

## Phase 8: Publish & present
1. Home > Publish > a workspace (My workspace is fine for a portfolio).
2. In the Service: set the Executive page as the landing page, configure **scheduled refresh** (needs a gateway if the file is local), pin a tile to a dashboard.
3. Export **8 page screenshots** (File > Export > PDF, or Windows snipping tool) and record a **60–90 s walkthrough** (see script in `docs/Interview_Prep.md`).
4. Create the GitHub repo: `.pbix`, screenshots, this folder, README. Link it from your resume and LinkedIn *Featured* section.
5. Optional: Publish to web only if you are comfortable with the (synthetic) data being public.

## Extension ideas (pick one for a "wow")
- **Forecast**: Analytics pane > Forecast on monthly revenue (12 points, 95% CI). Because the series is flat, this is a good place to discuss why a forecast is a baseline, not a prediction.
- **Anomaly detection** on the monthly revenue line.
- **Decomposition**: price/volume/mix bridge FY25 → FY26 (waterfall).
- **Copilot / Q&A**: add synonyms to the model so "turnover" resolves to Revenue.
- **Deployment pipeline** (Dev → Test → Prod) if you have Premium Per User.
