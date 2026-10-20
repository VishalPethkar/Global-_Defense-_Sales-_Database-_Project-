# Interview Prep: Global Defense Sales Analytics

## A. Your pitches

**30 seconds**
"I built an end-to-end Power BI project on 500,000 defence-equipment orders. I audited the data, modelled a star schema, wrote Power Query transformations and about 70 DAX measures, and validated them against SQL and Python. The big finding was that discounting, not pricing, drives margin: it falls from 24.7% to 8% as discounts rise. I built a what-if model showing a 10% discount cap is worth roughly 5 billion in profit and only backfires if more than 38% of affected orders are lost."

**90-second walkthrough (screen recording script)**
1. *(10s)* Executive page: "Realised revenue 173B, 16% margin, flat across three fiscal years."
2. *(15s)* Product page: "Ammunition is 77% of profit; eight products make 80%; two suppliers carry 71% of revenue."
3. *(10s)* Customer page: "Top 10% of customers give 46% of revenue."
4. *(30s)* Discount page: drag the cap slider to 10%, set attrition to 20%: "uplift stays positive; break-even is 38%."
5. *(15s)* Leakage page: "15% of order value leaks, uniformly across regions, so it is a process problem."
6. *(10s)* RFM page: "3,863 high-value customers have gone quiet: a win-back list."

**STAR story:** *Situation:* data looked clean but had hidden traps. *Task:* produce trustworthy KPIs. *Action:* audit; proved currency does not change prices; proved profit is zero on returns; defined "realised" = Completed; reconciled every measure to SQL/Python. *Result:* KPIs that tie out to the cent and a model that cannot double-count or mis-convert.

## B. Project questions
1. **Why Completed orders only?** Net_Profit is zero for Returned/Cancelled and only expected for Pending. Including them would mix realised and unrealised numbers and understate margin.
2. **Why no currency conversion? How did you verify?** Unit prices are numerically identical across the 7 currencies (a 9mm round is ≈ 36 in every one) and currency is 1:1 with country. Converting would make Japan look 150× smaller. I documented it as an assumption.
3. **How did you handle dirty data?** There were no nulls or duplicates; the work was in *validating logic* (profit formula, 1:1 keys, date order) and *normalising* (rounding discounts, parsing supplier country).
4. **What is the grain of the fact table?** One row per order.
5. **Why a star schema?** Simple filter propagation, fast aggregations, small model, intuitive for users, avoids ambiguous paths.
6. **Why single-direction relationships?** Avoids ambiguity and unexpected filtering; I use measures, not bi-directional filters, when I need cross-table logic.
7. **What is a role-playing dimension?** One date table used for several dates. Order Date is active; Ship Date is inactive and activated with `USERELATIONSHIP`.
8. **Why did you build a separate Dim_DiscountBand and Dim_OrderStatus?** Text columns sort alphabetically ("11-15%" before "6-10%"); the dimension supplies a sort key and grouping, and it can be reused in slicers.
9. **Explain the discount what-if.** For each of the 21 distinct discount values I recompute revenue with `MIN(discount, cap)`, keep cost constant, and subtract. Iterating over distinct values instead of 400K rows makes it near-instant. The attrition parameter removes a share of orders that used to exceed the cap; the break-even is `1 − profit_before / profit_after_cap` on the affected orders.
10. **What are the limits of that what-if?** No demand elasticity, costs fixed, no competitor response; it is a scenario for discussion, validated by a pilot.
11. **Why is the loss-making total small if 21K orders lose money?** Because they are small-margin dollars: ≈ 0.21B vs 28B profit. The business impact is *margin erosion on profitable orders*, which is much larger.
12. **What does "uniform 10% return rate" tell you?** Real operations rarely produce identical rates across every region/category; either it is a systemic process issue or the data is synthetic. I flag both.
13. **How would you forecast?** Start with a seasonal-naive or ETS baseline on monthly revenue. The series is flat (std dev ≈ 3.5% of mean), so I'd say the forecast is flat and focus on mix/discount levers.
14. **How would you extend RFM?** Cluster with k-means on log-transformed R, F, M; add churn probability; connect segments to campaigns and measure uplift.
15. **What would you do differently?** Add a price/volume/mix bridge, estimate elasticity from discount vs quantity, add incremental refresh, and write automated DAX tests.

## C. Power BI / DAX questions
16. **Calculated column vs measure?** A column is computed at refresh, per row, stored in the model (uses memory; good for slicing/sorting). A measure is computed at query time in the current filter context (no storage; good for aggregates). I used columns for row-level things (`Net_Revenue`, `Discount_Band`) and measures for all KPIs.
17. **Row context vs filter context; context transition?** Row context iterates rows (calculated columns, `SUMX`). Filter context comes from slicers/visual axes. `CALCULATE` inside an iterator turns the current row into filters, so `CALCULATE(SUM(...))` inside `SUMX(VALUES(discount), ...)` evaluates per discount value.
18. **`ALL` vs `ALLSELECTED` vs `REMOVEFILTERS`?** `ALL` removes filters from the named table/column regardless of slicers; `ALLSELECTED` removes only the visual's filters but keeps outer slicers (used for "share of visible total"); `REMOVEFILTERS` is the readable modifier version of `ALL` inside `CALCULATE`.
19. **Why `DIVIDE` not `/`?** It handles division by zero and returns BLANK instead of an error.
20. **`SAMEPERIODLASTYEAR` vs `DATEADD`?** Both shift a date column; `DATEADD` is general (any interval); `SAMEPERIODLASTYEAR` is the one-year shortcut. Both need a marked, contiguous date table.
21. **How did you do fiscal YTD?** I filtered `Dim_Date` for the same fiscal year up to the current max date; `TOTALYTD(…, "9/30")` is the shorthand but its year-end string is locale-dependent.
22. **How did you compute the Pareto?** `ADDCOLUMNS` over `ALLSELECTED(product)` to materialise profit per product, then sum all products whose profit ≥ the current one, divided by the total.
23. **Import vs DirectQuery vs Composite?** Import: fastest, 500K rows is trivial. DirectQuery for near-real-time or data too large for memory. Composite to combine both.
24. **How do you optimise a slow report?** Performance Analyzer; reduce cardinality (round discounts); remove unused columns; avoid bi-directional filters; replace row-by-row iterators with iteration over distinct values; avoid heavy measures on the same page; use aggregations or incremental refresh.
25. **How did you implement row-level security and test it?** Role filters on `Dim_Customer[Customer_Region]`, dynamic version via `USERPRINCIPALNAME()` and a mapping table; tested with *View as*; filters propagate to the fact through the relationship.
26. **What are the 3 steps you take before sharing a report?** Reconcile numbers to source, test with slicers/edge cases, and check accessibility + mobile.

## D. SQL questions (see `sql/analysis_queries.sql`)
- *Window functions:* `LAG` for YoY (Q02), `SUM() OVER` for share and Pareto (Q06, Q07), moving average (Q11), `ROW_NUMBER` for top-10% customers (Q10).
- *Difference between `WHERE` and `HAVING`; `RANK` vs `DENSE_RANK` vs `ROW_NUMBER`; CTE vs subquery; `INNER` vs `LEFT JOIN`.*
- *How would you find duplicate Order_IDs?* `SELECT Order_ID, COUNT(*) FROM Fact_Sales GROUP BY Order_ID HAVING COUNT(*) > 1;`

## E. Behavioural / business-analyst questions
- **How do you handle a stakeholder who wants a different definition of revenue?** Show both (Completed vs all-orders) side by side, agree on one governed definition, document it on the About page.
- **Tell me about a time data surprised you.** The currency column: the "obvious" step (convert FX) would have been wrong; I tested before transforming.
- **How do you prioritise recommendations?** Size (profit impact), confidence (evidence), effort/risk; the discount cap scores high on all three, so it leads.
- **How would you measure whether the discount cap worked?** Pilot in one region vs matched control; track win rate, attrition among affected orders, margin and profit per order for 3 months.

## F. Honest answer to "Is this real data?"
"It looks synthetic: margins, return rates and discount frequencies are near-identical across every dimension, and the currency column doesn't change prices. I treated that as a finding, avoided over-interpreting uniform patterns, and focused on the methods (audit, modelling, validation, scenario analysis), which are the same on real data."
