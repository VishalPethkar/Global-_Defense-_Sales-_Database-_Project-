// ============================================================
// 03 | Customer_RFM   (staging query - disable "Enable load")
// Static RFM snapshot as of 1 Oct 2026 (day after the last order), realised orders only.
//   Recency  : <=90d=5, <=180d=4, <=365d=3, <=540d=2, else 1
//   Frequency: 1=1, 2=2, 3=3, 4-5=4, 6+=5
//   Monetary : quintile of lifetime revenue (data-driven thresholds)
// ============================================================
let
    AsOf      = #date(2026, 10, 1),
    Completed = Table.SelectRows(Fact_Sales, each [Order_Status] = "Completed"),
    Grouped   = Table.Group(Completed, {"Customer_ID"}, {
                    {"Last_Order_Date",  each List.Max([Order_Date]),  type date},
                    {"Order_Count",      each Table.RowCount(_),       Int64.Type},
                    {"Lifetime_Revenue", each List.Sum([Net_Revenue]), type number}}),
    Rec       = Table.AddColumn(Grouped, "Recency_Days", each Duration.Days(AsOf - [Last_Order_Date]), Int64.Type),

    // quintile cut-offs for Monetary (index method: sorted[floor(n*p)])
    SortedM   = List.Buffer(List.Sort(Rec[Lifetime_Revenue])),
    n         = List.Count(SortedM),
    T20       = SortedM{Number.RoundDown(n * 0.2)},
    T40       = SortedM{Number.RoundDown(n * 0.4)},
    T60       = SortedM{Number.RoundDown(n * 0.6)},
    T80       = SortedM{Number.RoundDown(n * 0.8)},

    R   = Table.AddColumn(Rec, "R_Score", each
              if [Recency_Days] <= 90 then 5 else if [Recency_Days] <= 180 then 4
              else if [Recency_Days] <= 365 then 3 else if [Recency_Days] <= 540 then 2 else 1, Int64.Type),
    F   = Table.AddColumn(R, "F_Score", each
              if [Order_Count] = 1 then 1 else if [Order_Count] = 2 then 2 else if [Order_Count] = 3 then 3
              else if [Order_Count] <= 5 then 4 else 5, Int64.Type),
    M   = Table.AddColumn(F, "M_Score", each
              1 + (if [Lifetime_Revenue] >= T20 then 1 else 0) + (if [Lifetime_Revenue] >= T40 then 1 else 0)
                + (if [Lifetime_Revenue] >= T60 then 1 else 0) + (if [Lifetime_Revenue] >= T80 then 1 else 0), Int64.Type),
    Seg = Table.AddColumn(M, "RFM_Segment", each
              if [R_Score] >= 4 and [F_Score] >= 4 then "Champions"
              else if [R_Score] <= 2 and [F_Score] >= 3 and [M_Score] >= 4 then "High-Value At Risk"
              else if [R_Score] <= 2 and [F_Score] >= 3 then "At Risk"
              else if [F_Score] >= 3 then "Loyal"
              else if [R_Score] >= 4 then "New / Recent"
              else if [R_Score] = 3 then "Promising"
              else "Hibernating", type text),
    Out = Table.SelectColumns(Seg, {"Customer_ID","Recency_Days","Order_Count","Lifetime_Revenue",
                                    "R_Score","F_Score","M_Score","RFM_Segment"})
in
    Out
