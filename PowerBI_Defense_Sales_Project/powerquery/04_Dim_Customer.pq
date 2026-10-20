// ============================================================
// 04 | Dim_Customer   (strict 1:1 Customer_ID -> country / segment, verified in the audit)
// Joins the static RFM attributes. Customers with no completed order get "No Completed Orders".
// ============================================================
let
    Source = Table.SelectColumns(Raw, {"Customer_ID","Customer_Segment","Customer_Country","Customer_Region","Local_Currency"}),
    Dedup  = Table.Distinct(Source, {"Customer_ID"}),
    Joined = Table.NestedJoin(Dedup, {"Customer_ID"}, Customer_RFM, {"Customer_ID"}, "RFM", JoinKind.LeftOuter),
    Expand = Table.ExpandTableColumn(Joined, "RFM",
                 {"Recency_Days","Order_Count","Lifetime_Revenue","R_Score","F_Score","M_Score","RFM_Segment"}),
    Filled = Table.ReplaceValue(Expand, null, "No Completed Orders", Replacer.ReplaceValue, {"RFM_Segment"}),
    Sorted = Table.Sort(Filled, {{"Customer_ID", Order.Ascending}})
in
    Sorted
