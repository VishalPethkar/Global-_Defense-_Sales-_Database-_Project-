// ============================================================
// 01 | Fact_Sales   (Reference Raw - never duplicate it)
// What it does:
//   * rounds Discount_Applied to 2 dp (kills floating-point noise; gives only 21 distinct values,
//     which makes the discount what-if DAX very fast)
//   * adds Gross_Sales, Discount_Amount, Net_Revenue, Total_Cost, Ship_Days
//   * adds Discount_Band (text) and Is_Loss_Making (1/0 flag)
//   * keeps only the columns the model needs (smaller model, faster refresh)
// ============================================================
let
    Source  = Raw,
    Disc    = Table.TransformColumns(Source, {{"Discount_Applied", each Number.Round(_, 2), type number}}),
    Gross   = Table.AddColumn(Disc,  "Gross_Sales",     each Number.Round([Unit_Selling_Price] * [Order_Quantity], 2), type number),
    NetRev  = Table.AddColumn(Gross, "Net_Revenue",     each Number.Round([Gross_Sales] * (1 - [Discount_Applied]), 2), type number),
    DiscAmt = Table.AddColumn(NetRev,"Discount_Amount", each Number.Round([Gross_Sales] - [Net_Revenue], 2), type number),
    Cost    = Table.AddColumn(DiscAmt,"Total_Cost",     each Number.Round([Unit_Cost] * [Order_Quantity], 2), type number),
    Ship    = Table.AddColumn(Cost,  "Ship_Days",       each Duration.Days([Ship_Date] - [Order_Date]), Int64.Type),
    Band    = Table.AddColumn(Ship,  "Discount_Band", each
                  if [Discount_Applied] = 0    then "0%"
             else if [Discount_Applied] <= 0.05 then "1-5%"
             else if [Discount_Applied] <= 0.10 then "6-10%"
             else if [Discount_Applied] <= 0.15 then "11-15%"
             else "16-20%", type text),
    Loss    = Table.AddColumn(Band, "Is_Loss_Making",
                  each if [Order_Status] = "Completed" and [Net_Profit] < 0 then 1 else 0, Int64.Type),
    Keep    = Table.SelectColumns(Loss, {
                  "Order_ID","Order_Date","Ship_Date","Order_Status","Customer_ID","Product_ID",
                  "Unit_Cost","Unit_Selling_Price","Order_Quantity","Discount_Applied","Discount_Band",
                  "Gross_Sales","Discount_Amount","Net_Revenue","Total_Cost","Net_Profit",
                  "Ship_Days","Is_Loss_Making"})
in
    Keep
