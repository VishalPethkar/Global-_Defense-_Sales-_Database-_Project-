# Case Study: Where is the margin going? Global Defense Sales

*A 3-minute read for recruiters and hiring managers.*

## Context
A global defence-equipment distributor sells ammunition, firearms and armour to militaries, law-enforcement agencies, private security firms and individuals in 7 countries. Leadership has 500,000 orders (Oct 2023 – Sep 2026) and wants to know where profit comes from and what is leaking it.

## My approach
1. **Audited the data first.** No nulls or duplicates, but three traps: (a) the currency column does not change prices, so converting FX would corrupt the numbers; (b) `Net_Profit` is zero for returned and cancelled orders and only expected for pending ones, so KPIs must use *Completed* orders; (c) product and customer attributes are strictly 1:1, which makes a clean star schema possible.
2. **Modelled a star schema** (1 fact, 5 dimensions) with a fiscal calendar starting in October, a role-playing ship-date relationship, and parameter tables for what-if analysis.
3. **Built 70+ DAX measures** (core KPIs, YoY/YTD/rolling, Pareto, concentration, leakage, what-if) and validated each against independent Python and SQL calculations.
4. **Segmented customers with RFM** and quantified concentration (customers, products, suppliers).
5. **Designed an 8-page report** whose chart titles state the finding.

## What I found
**1. Discounts, not pricing, are eroding margin.** Realised margin drops from 24.7% with no discount to 8.0% at 16–20%. Every one of the 20,979 loss-making orders carried a discount of at least 14%. Those orders total only ≈ 0.21B of losses, so the issue is the *margin given away on profitable orders*, not the loss-makers themselves.

**2. A discount cap is the biggest lever, and it is robust.** Capping discounts at 10% would add ≈ 5.05B profit (+18%) if volume held. The cap still creates value unless **more than 37.9%** of the 190,570 affected orders are lost, a high bar that a controlled pilot can test.

| Cap | Orders affected | Profit uplift (no attrition) | Break-even attrition |
|---|---|---|---|
| 5% | 71.5% | +10.99B | 41.0% |
| 10% | 47.6% | +5.05B | 37.9% |
| 12% | 38.1% | +3.31B | 35.9% |
| 15% | 23.9% | +1.38B | 31.4% |

**3. 15% of order value leaks.** 10% of orders are returned and 5% cancelled (≈ 32.8B of order value, ≈ 5.3B of estimated profit). The rates are ~10% and ~5% in *every* region, category and segment, which points to a company-wide process issue (order accuracy, documentation, delivery) rather than a bad product or market.

**4. The business is an ammunition business.** Ammunition is 77% of revenue and profit; 8 of 51 products make 80% of profit. Two suppliers provide 71% of revenue (HHI ≈ 2,656, highly concentrated).

**5. Customers are concentrated and some valuable ones are drifting.** The top 10% of customers deliver 46.4% of revenue. 3,863 "High-Value At Risk" customers (formerly frequent, now silent for 12+ months) have 12.3B of lifetime revenue.

**6. Growth is flat.** FY24 58.0B → FY25 57.3B → FY26 58.1B. Margin is ~16% in every segment, region and category, so profit is driven by *volume mix and discount discipline*.

## Recommendations
1. Introduce a **10% discount ceiling with approval above it** (est. +5.1B at constant volume; test in one region first to measure real attrition).
2. Launch a **returns & cancellations root-cause review** (target: halve the 15% leakage).
3. **Dual-source ammunition** to reduce reliance on two suppliers.
4. **Key-account management** for the top 10% and a **win-back programme** for High-Value At Risk customers.
5. Grow **non-ammunition** categories (23% of revenue) through bundling with ammunition orders.

## Caveats (stated honestly)
The dataset appears synthetic (near-uniform return rates, margins and discount frequencies). The discount what-if assumes unchanged costs and no demand response unless attrition is set; it is a scenario tool, not a forecast. No FX conversion was applied because prices are numerically identical across currencies. YoY is not available for FY2024.

## What I would do next
Price/volume/mix bridge between fiscal years · demand-elasticity estimate from discount vs quantity · churn model on RFM · incremental refresh and a deployment pipeline for production.
