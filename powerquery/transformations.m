// =====================================================================
// NYC Payroll Operations Dashboard (FY2025) - Power Query (M)
// Paste into: Power BI > Transform Data > Advanced Editor
// Query name in the model: Payroll
// =====================================================================
let
    // 1. Load FY2025 from the official NYC OData endpoint (filtered on the server for speed)
    Source = OData.Feed("https://data.cityofnewyork.us/api/odata/v4/k397-673e?$filter=fiscal_year%20eq%202025", null, [Implementation="2.0"]),

    // 2. Keep only the 12 columns needed for payroll analysis
    #"Select Columns" = Table.SelectColumns(Source,
        {"fiscal_year", "payroll_number", "agency_name", "title_description",
         "work_location_borough", "leave_status_as_of_june_30", "base_salary",
         "pay_basis", "regular_hours", "regular_gross_paid", "ot_hours", "total_ot_paid"}),

    // 3. Set data types so numeric fields calculate correctly
    #"Set Data Types" = Table.TransformColumnTypes(#"Select Columns",
        {{"fiscal_year", Int64.Type}, {"payroll_number", Int64.Type},
         {"agency_name", type text}, {"title_description", type text},
         {"work_location_borough", type text}, {"leave_status_as_of_june_30", type text},
         {"base_salary", type number}, {"pay_basis", type text},
         {"regular_hours", type number}, {"regular_gross_paid", type number},
         {"ot_hours", type number}, {"total_ot_paid", type number}}),

    // 4. Trim spaces and use one consistent case (upper keeps acronyms like NYC intact)
    #"Standardise Text" = Table.TransformColumns(#"Set Data Types",
        {{"agency_name", each Text.Upper(Text.Trim(_)), type text},
         {"title_description", each Text.Upper(Text.Trim(_)), type text},
         {"work_location_borough", each Text.Upper(Text.Trim(_)), type text},
         {"leave_status_as_of_june_30", each Text.Upper(Text.Trim(_)), type text},
         {"pay_basis", each Text.Upper(Text.Trim(_)), type text}}),

    // 5. Missing pay or hours means none was paid, so null becomes 0
    //    (base_salary is excluded on purpose: missing salary is unknown, not zero)
    #"Replace Null Pay" = Table.ReplaceValue(#"Standardise Text", null, 0, Replacer.ReplaceValue,
        {"regular_hours", "regular_gross_paid", "ot_hours", "total_ot_paid"}),

    // 6. Use business-friendly column names for report users
    #"Rename Columns" = Table.RenameColumns(#"Replace Null Pay",
        {{"fiscal_year", "Fiscal Year"}, {"payroll_number", "Payroll Number"},
         {"agency_name", "Agency Name"}, {"title_description", "Title Description"},
         {"work_location_borough", "Borough"}, {"leave_status_as_of_june_30", "Leave Status"},
         {"base_salary", "Base Salary"}, {"pay_basis", "Pay Basis"},
         {"regular_hours", "Regular Hours"}, {"regular_gross_paid", "Regular Gross Paid"},
         {"ot_hours", "OT Hours"}, {"total_ot_paid", "Total OT Paid"}}),

    // 7. Annual salary only for per-annum staff, so salaries are comparable
    #"Add Annual Salary" = Table.AddColumn(#"Rename Columns", "Annual Salary",
        each if [Pay Basis] = "PER ANNUM" then [Base Salary] else null, type number),

    // 8a. Salary bands for the distribution chart (clean labels)
    #"Add Salary Band" = Table.AddColumn(#"Add Annual Salary", "Salary Band",
        each if [Annual Salary] = null then "Not annual salary"
             else if [Annual Salary] < 50000 then "Under 50K"
             else if [Annual Salary] < 75000 then "50K-75K"
             else if [Annual Salary] < 100000 then "75K-100K"
             else if [Annual Salary] < 150000 then "100K-150K"
             else "150K+", type text),

    // 8b. Sort order for the bands (Power BI: Salary Band > Sort by column > Salary Band Order)
    #"Add Salary Band Order" = Table.AddColumn(#"Add Salary Band", "Salary Band Order",
        each if [Annual Salary] = null then 0
             else if [Annual Salary] < 50000 then 1
             else if [Annual Salary] < 75000 then 2
             else if [Annual Salary] < 100000 then 3
             else if [Annual Salary] < 150000 then 4
             else 5, Int64.Type),

    // 9. Flag records with overtime
    #"Add Overtime Flag" = Table.AddColumn(#"Add Salary Band Order", "Has Overtime",
        each if [Total OT Paid] > 0 then "Yes" else "No", type text),

    // 10. Flag negative pay (payroll adjustments) instead of deleting it
    #"Add Negative Pay Flag" = Table.AddColumn(#"Add Overtime Flag", "Has Negative Pay",
        each if [Regular Gross Paid] < 0 or [Total OT Paid] < 0 then "Yes" else "No", type text)
in
    #"Add Negative Pay Flag"
