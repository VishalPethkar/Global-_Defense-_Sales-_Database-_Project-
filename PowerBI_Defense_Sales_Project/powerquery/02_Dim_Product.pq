// ============================================================
// 02 | Dim_Product   (strict 1:1 Product_ID -> category / supplier, verified in the audit)
// Enrichment: supplier country + short name parsed from "Name (Country)", Ammunition flag
// ============================================================
let
    Source  = Table.SelectColumns(Raw, {"Product_ID","Product_Name","Product_Category","Supplier_Name"}),
    Dedup   = Table.Distinct(Source, {"Product_ID"}),
    Short   = Table.AddColumn(Dedup, "Supplier_Short",
                  each Text.Trim(Text.BeforeDelimiter([Supplier_Name], "(", {0, RelativePosition.FromEnd})), type text),
    RawCtry = Table.AddColumn(Short, "Supplier_Country_Raw",
                  each Text.BetweenDelimiters([Supplier_Name], "(", ")", {0, RelativePosition.FromEnd}, 0), type text),
    // "AWEIL India" is a company alias, not a country
    Ctry    = Table.AddColumn(RawCtry, "Supplier_Country",
                  each if Text.Contains([Supplier_Country_Raw], "AWEIL") then "India" else [Supplier_Country_Raw], type text),
    Grp     = Table.AddColumn(Ctry, "Product_Group",
                  each if [Product_Category] = "Ammunition" then "Ammunition" else "Non-Ammunition", type text),
    Out     = Table.RemoveColumns(Grp, {"Supplier_Country_Raw"}),
    Sorted  = Table.Sort(Out, {{"Product_ID", Order.Ascending}})
in
    Sorted
