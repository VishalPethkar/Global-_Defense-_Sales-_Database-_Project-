// ============================================================
// 05 | QUICK START (skip all the Excel transformations)
// The /data folder already contains the finished star schema as CSVs.
// Get Data > Text/CSV > pick each file, or use this pattern for every table:
// ============================================================
// Parameter: DataFolder = "C:\Projects\DefenseSales\data\"

// ---- Fact_Sales
let
    Source = Csv.Document(File.Contents(DataFolder & "Fact_Sales.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Header = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Typed  = Table.TransformColumnTypes(Header, {
        {"Order_ID", type text}, {"Order_Date", type date}, {"Ship_Date", type date},
        {"Order_Status", type text}, {"Customer_ID", type text}, {"Product_ID", type text},
        {"Unit_Cost", type number}, {"Unit_Selling_Price", type number}, {"Order_Quantity", Int64.Type},
        {"Discount_Applied", type number}, {"Discount_Band", type text}, {"Gross_Sales", type number},
        {"Discount_Amount", type number}, {"Net_Revenue", type number}, {"Total_Cost", type number},
        {"Net_Profit", type number}, {"Ship_Days", Int64.Type}, {"Is_Loss_Making", Int64.Type}}, "en-US")
in
    Typed

// ---- Any dimension (example: Dim_Customer) - set types the same way
// let
//     Source = Csv.Document(File.Contents(DataFolder & "Dim_Customer.csv"), [Delimiter = ",", Encoding = 65001]),
//     Header = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
//     Typed  = Table.TransformColumnTypes(Header, {{"Recency_Days", Int64.Type}, {"Order_Count", Int64.Type},
//                {"Lifetime_Revenue", type number}, {"R_Score", Int64.Type}, {"F_Score", Int64.Type}, {"M_Score", Int64.Type}}, "en-US")
// in
//     Typed
