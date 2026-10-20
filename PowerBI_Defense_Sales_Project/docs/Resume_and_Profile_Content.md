# Resume, LinkedIn & GitHub Content

> **Rule #1: only claim what you actually built.** These bullets are written for a finished report that follows the Build Guide. If you skip a feature (e.g., RLS, incremental refresh), delete that phrase. Every number below is verified against the data; keep them identical to your dashboard.

## 1. Master project entry (use on any resume)

**Global Defense Sales Analytics | Power BI, DAX, Power Query, SQL** · [GitHub link]
- Designed an end-to-end analytics solution on **500K orders (173B realised revenue)**: audited the data, built a **star-schema model** (1 fact, 5 dimensions, role-playing date table) and **70+ DAX measures** (YoY, fiscal YTD, rolling average, Pareto, concentration), reconciled to independent SQL and Python calculations.
- Found that **margin falls from 24.7% to 8.0%** as discounts rise from 0% to 20%; built an interactive **what-if model** showing a 10% discount cap adds **≈ 5.1B profit (+18%)** and only backfires if **>38% of affected orders are lost**.
- Quantified **15% revenue leakage** (≈ 32.8B) from returns and cancellations and showed the rate is uniform across regions and categories, pointing to a **process issue**, not a product or market issue.
- Segmented 91K customers with **RFM** (identified 3,863 high-value at-risk accounts holding 12.3B lifetime revenue) and measured **concentration** (top-10% customers = 46% of revenue; two suppliers = 71%, HHI 2,656).
- Delivered an 8-page report with synced slicers, drill-through, tooltip pages, bookmarks and dynamic titles; documented assumptions (no FX conversion, synthetic data) in a data-notes page.

## 2. Role-specific versions (pick 4 bullets, put the strongest first)

### Data Analyst
- Audited 500K rows (nulls, duplicates, key integrity, profit logic, currency) and documented 6 data-quality decisions that prevented incorrect FX conversion and mixing of realised and unrealised profit.
- Wrote **15 SQL queries** (CTEs, window functions: `LAG`, `SUM() OVER`, moving averages, `ROW_NUMBER`) and used them to validate every Power BI KPI to the cent.
- Identified a **24.7% → 8.0% margin decline** across discount bands and traced all 20,979 loss-making orders to discounts ≥ 14%.
- Built RFM segmentation and Pareto/concentration analyses (8 of 51 products = 80% of profit; top-10% customers = 46% of revenue).
- Presented findings as a data story with 5 prioritised recommendations.

### Business Analyst
- Translated six leadership questions (profit drivers, leakage, discounting, concentration, customer value) into a KPI framework and an 8-page decision-support report.
- Quantified the value of a **10% discount ceiling (+5.1B profit, +18%)** with a break-even attrition test (38%), giving stakeholders a risk-adjusted business case.
- Sized **15% order-value leakage** (≈ 32.8B) and recommended a returns/cancellation root-cause review, a supplier dual-sourcing plan (top-2 = 71% of revenue) and a key-account programme.
- Documented definitions, assumptions and limitations (realised revenue, no FX, synthetic data) to make the numbers auditable.
- Specified a pilot design (test vs control region) to measure the real impact of the discount policy.

### BI Developer / Power BI Developer
- Engineered a **star schema** with Power Query (M) staging queries, a **role-playing date dimension**, sort/grouping dimensions and disconnected **what-if parameter tables**; Import mode with a compact model.
- Authored **70+ DAX measures** across 8 display folders using `CALCULATE`, `SUMX`, `RANKX`, `TOPN`, `ALLSELECTED`, `USERELATIONSHIP`, variables and iterators over distinct values for sub-second what-if performance.
- Implemented **row-level security** (static and dynamic via `USERPRINCIPALNAME`), field parameters, drill-through, custom tooltips, bookmarks and a custom JSON theme.
- Tuned performance with Performance Analyzer (cardinality reduction, unused-column removal, Auto date/time off) and defined an incremental-refresh pattern for growth.
- Published to Power BI Service with scheduled refresh and documented the build for hand-over.

### Sales / Commercial / Pricing Analyst
- Built a **discount-to-margin curve** (24.7% → 8.0%) and a **cap what-if with break-even attrition**, showing that a 10% cap is worth ≈ 5.1B profit at constant volume.
- Identified that **ammunition drives 77% of revenue and profit** and that APAC contributes 43% of revenue while the USA is the largest single country (23.6%).
- Segmented customers with RFM and built a win-back list of **3,863 high-value, at-risk accounts** (12.3B lifetime revenue).
- Tracked fiscal-year growth (FY24 58.0B → FY26 58.1B, flat) and highlighted mix and discount discipline as the profit levers.

## 3. Skills line (reorder per job description)
`Power BI · DAX · Power Query (M) · Data Modelling (Star Schema) · SQL (CTEs, Window Functions) · KPI Design · Sales & Margin Analysis · Customer Segmentation (RFM) · What-If / Scenario Analysis · Data Storytelling · Row-Level Security · Excel`

**ATS keywords to mirror from job postings:** data visualisation, dashboard, KPI, stakeholder, requirements gathering, ETL, data cleansing, data validation, reporting, ad-hoc analysis, forecasting, root-cause analysis, process improvement, Power BI Service, scheduled refresh, SQL Server.

## 4. LinkedIn

**Headline options**
- `Data & Business Analyst | Power BI · DAX · SQL | Turning sales data into margin decisions`
- `BI Developer | Power BI, DAX, Power Query, Star Schema | 500K-order analytics project`

**About (short)**
"I turn messy sales data into decisions. My latest project analyses 500,000 defence-equipment orders in Power BI: I audited the data, modelled a star schema, wrote 70+ DAX measures, validated everything in SQL and built a discount what-if showing a 10% cap could add ~5B profit. I'm looking for Data Analyst / BI roles where I can combine business questions with clean models and clear stories."

**Featured post (project announcement)**
"New portfolio project: Global Defense Sales Analytics (Power BI + SQL).
What I found in 500K orders: margin falls from 24.7% to 8% as discounts rise; a 10% discount cap is worth ~5B profit and only fails if >38% of affected orders are lost; 15% of order value leaks through returns/cancellations at a uniform rate (a process problem); two suppliers carry 71% of revenue.
Built with a star schema, Power Query, 70+ DAX measures, RFM segmentation and validated in SQL. Repo + 90-second walkthrough in the comments. Honest caveat: the data looks synthetic, and I say so in the report. Feedback welcome."

## 5. GitHub
- **Repo name:** `defense-sales-powerbi-analytics`
- **Description:** "End-to-end Power BI project: star schema, Power Query, 70+ DAX measures, SQL validation, RFM segmentation and discount what-if on 500K orders."
- **Topics:** `power-bi` `dax` `power-query` `data-analysis` `business-intelligence` `sql` `star-schema` `rfm-analysis` `portfolio-project` `data-visualization`
- **Pin** the repo; include 8 screenshots in the README and the 90-second video link.
