// ============================================================
// 00 | PARAMETER + RAW   (create these two FIRST)
// ============================================================

// ---- Query name: FilePath  (Type: Text, Required) ----------
// Home > Manage Parameters > New Parameter
//   Name:  FilePath
//   Type:  Text
//   Value: C:\Projects\DefenseSales\Global_Defense_Sales_Data_500K.xlsx
// Using a parameter means the file location can change without editing any query.

// ---- Query name: Raw  (disable "Enable load" - staging only)
let
    Source   = Excel.Workbook(File.Contents(FilePath), null, true),
    Sheet    = Source{[Item = "Sales_Data", Kind = "Sheet"]}[Data],
    Promoted = Table.PromoteHeaders(Sheet, [PromoteAllScalars = true]),
    Typed    = Table.TransformColumnTypes(Promoted, {
        {"Order_ID", type text}, {"Order_Date", type date}, {"Ship_Date", type date},
        {"Order_Status", type text}, {"Customer_ID", type text}, {"Customer_Segment", type text},
        {"Customer_Country", type text}, {"Customer_Region", type text},
        {"Product_ID", type text}, {"Product_Name", type text}, {"Product_Category", type text},
        {"Supplier_Name", type text}, {"Local_Currency", type text},
        {"Unit_Cost", type number}, {"Unit_Selling_Price", type number},
        {"Order_Quantity", Int64.Type}, {"Discount_Applied", type number}, {"Net_Profit", type number}})
in
    Typed
