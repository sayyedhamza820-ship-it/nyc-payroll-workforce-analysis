# Data Dictionary

**Source:** [NYC Citywide Payroll Data (Fiscal Year)](https://data.cityofnewyork.us/City-Government/Citywide-Payroll-Data-Fiscal-Year-/k397-673e), NYC Open Data / Office of Payroll Administration.
**Scope:** Fiscal Year 2025. **Grain:** one row per employee-title-agency payroll record (not necessarily one person).
**Why this file exists:** anyone reading the dashboard should know exactly what each field means and how it was derived.

## Source columns kept (12 of 17)

| Source field | Name in model | Type | Meaning | Why it is kept |
|---|---|---|---|---|
| fiscal_year | Fiscal Year | Whole number | City fiscal year of the record | Confirms the year filter |
| payroll_number | Payroll Number | Whole number | Agency payroll code | Counting records |
| agency_name | Agency Name | Text (upper case) | Employing agency | Main cost and overtime dimension |
| title_description | Title Description | Text (upper case) | Job title | Role-level overtime and salary |
| work_location_borough | Borough | Text (upper case) | Work location borough | Geographic view |
| leave_status_as_of_june_30 | Leave Status | Text (upper case) | Active, ceased, on leave, etc. as of June 30 | Separates active from inactive records |
| base_salary | Base Salary | Decimal | Pay rate; unit depends on Pay Basis | Salary analysis |
| pay_basis | Pay Basis | Text (upper case) | PER ANNUM, PER DAY, PER HOUR, PRORATED ANNUAL | Needed to compare salaries correctly |
| regular_hours | Regular Hours | Decimal | Regular hours paid | Regular work effort |
| regular_gross_paid | Regular Gross Paid | Decimal | Regular gross pay in the year | Core cost measure |
| ot_hours | OT Hours | Decimal | Overtime hours | Overtime effort |
| total_ot_paid | Total OT Paid | Decimal | Overtime pay in the year | Overtime cost |

## Columns created in Power Query

| Column | Rule | Why |
|---|---|---|
| Annual Salary | Base Salary where Pay Basis = PER ANNUM, otherwise blank | Hourly, daily and annual rates cannot be averaged together |
| Salary Band | Under 50K, 50K-75K, 75K-100K, 100K-150K, 150K+, or Not annual salary | Shows the pay distribution |
| Salary Band Order | 0 to 5 | Sort key so bands display in salary order |
| Has Overtime | Yes if Total OT Paid > 0 | Simple overtime prevalence measure |
| Has Negative Pay | Yes if regular or overtime pay < 0 | Flags payroll adjustments instead of deleting them |

## Data handling notes
- Null hours and pay amounts are set to 0 (nothing was paid). Null Base Salary stays null (unknown, not zero).
- Text is trimmed and converted to upper case to avoid duplicate agency or title labels.
- Employee names are not loaded.
