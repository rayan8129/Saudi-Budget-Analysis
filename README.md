# Saudi Arabia Budget Analysis (1993 – 2020)

A data analysis project on Saudi Arabia's public finances, covering 28 years of revenues, expenditures, and budget surplus/deficit. It includes a Python notebook, a SQLite database with SQL queries, and an interactive Power BI dashboard.

## Overview

The project answers a few key questions:

- How did revenues and expenditures evolve over 28 years?
- How dependent is the budget on oil, and has that changed?
- How is spending split between operating and capital expenditure?
- When did the budget run a surplus, and when a deficit?
- What is the general trend of revenues going forward?

## Data

| Item | Details |
|---|---|
| File | `data/data.xlsx` (sheet `public finance`), plus a SQLite copy in `data/saudi_budget.db` |
| Period | 1993 – 2020 (28 years) |
| Unit | Million Saudi riyals (SAR) |
| Columns | Year, Total revenue, Oil revenue, Non-oil revenue, Total expenditure, Operating expenditure, Capital expenditure, Budget surplus/deficit (original column names are in Arabic) |

**Data quality check:** no missing values, and the accounting identities hold in every year:

- Revenue = Oil + Non-oil
- Expenditure = Operating + Capital (rounding differences of at most 1 million SAR)
- Surplus/Deficit = Revenue − Expenditure

> Note: 2017 and 2019 contain decimal values in revenue, as in the source file.

## Notebook and Database

`notebook/saudi_budget_analysis.ipynb` performs four steps:

1. Reads `data.xlsx`, cleans empty rows, and renames columns.
2. Plots revenue vs. expenditure (Matplotlib).
3. Fits a linear regression (scikit-learn) to project revenue for 2021–2025.
4. Stores the table in SQLite (`saudi_budget.db`, table `public_finances_sql`) and queries the years in which revenue exceeded SAR 1 trillion.

**Query result:** only five years exceeded SAR 1 trillion in revenue: 2008, 2011, 2012, 2013, and 2014.

```sql
SELECT السنة, الإيرادات, النفقات, [فائض/عجز الميزانية]
FROM public_finances_sql
WHERE الإيرادات > 1000000
ORDER BY السنة DESC;
```

(Columns: year, revenue, expenditure, surplus/deficit.)

### Revenue projection (linear trend)

![Revenue linear trend](images/revenue_forecast.png)

| Year | Projected revenue (SAR billion) |
|---|---|
| 2021 | 1,073 |
| 2022 | 1,108 |
| 2023 | 1,144 |
| 2024 | 1,179 |
| 2025 | 1,214 |

> **Caution:** this is a simple linear regression on year only (R² ≈ 0.63, slope ≈ SAR 35 billion per year). It illustrates the general trend and nothing more. It ignores oil prices and sharp swings such as the 2015 drop, and should not be treated as a reliable forecast.

## SQL Analysis

The analysis is repeated in SQL on the SQLite database. `notebook/sql_analysis.py` loads `data/data.xlsx` into `data/saudi_budget.db` and runs every query in `notebook/queries.sql`:

| Object | Type | Description |
|---|---|---|
| `public_finances_sql` | table | The 28 yearly rows with the original Arabic column names |
| `budget` | view | The same data with English column names (`Year`, `Revenue`, `Oil_Revenue`, `NonOil_Revenue`, `Expenditure`, `Operating_Exp`, `Capital_Exp`, `Balance`), in million SAR |

`queries.sql` has 12 queries that use `CASE`, `UNION`, self-joins, CTEs, and window functions (`LAG`, `RANK`, running `SUM() OVER`):

| # | Question | SQL techniques |
|---|---|---|
| Q1 | Overview: years, total revenue, spending, cumulative balance | Aggregates |
| Q2 | Do the accounting identities hold in every year? | `MAX(ABS(...))` |
| Q3 | Years when revenue exceeded SAR 1 trillion | `WHERE`, `ORDER BY` |
| Q4 | Surplus years vs. deficit years | `CASE`, `GROUP BY` |
| Q5 | Largest surplus and largest deficit | `UNION ALL`, sub-queries |
| Q6 | Oil share of revenue by year, with the yearly change | `LAG() OVER` |
| Q7 | Peak and latest oil dependence | `UNION ALL` |
| Q8 | Top 5 years by capital spending share | CTE, `RANK() OVER` |
| Q9 | Averages by period (1993-1999, 2000-2009, 2010-2020) | `CASE`, `GROUP BY` |
| Q10 | The five worst years of revenue growth | CTE, `LAG`, `RANK` |
| Q11 | Running total of the balance since 1993 | CTE, `SUM() OVER` |
| Q12 | 2014-2020 cumulative balance and non-oil revenue growth | Self-join |

### Key SQL findings

- **The identities hold**: the largest gap is 0 for revenue and balance, and 1 million SAR for expenditure (rounding), which confirms the data quality check above.
- **The SQL results match the notebook and dashboard**: the five years above SAR 1 trillion (2008, 2011, 2012, 2013, 2014), the 11 surplus and 17 deficit years, and the peak oil share of 92.6% in 2011 are all reproduced.
- **Surpluses were mostly erased by deficits**: surplus years added about SAR 2.29 trillion and deficit years took away about SAR 2.00 trillion. The cumulative balance peaked at about SAR 1.92 trillion in 2013 and fell to about SAR 289 billion by 2020.
- **Revenue is volatile**: the worst yearly drops were 2009 (-53.7%), 2015 (-41.1%), and 1998 (-31.1%).
- **Two different decades**: 2000-2009 averaged a surplus of about SAR 129 billion a year, while 2010-2020 averaged a deficit of about SAR 70 billion a year, even though average revenue rose from SAR 488 billion to SAR 885 billion, because spending averaged SAR 955 billion.
- **Capital spending peaks**: the highest capital shares were 2009 (30.2%), 2011 (29.4%), and 2014 (28.0%).

**Run the SQL step** (from the repository root):
```bash
pip install pandas openpyxl
python notebook/sql_analysis.py   # rebuilds data/saudi_budget.db, then runs and prints all queries
```
SQLite needs no installation, since `sqlite3` ships with Python.

## Power BI Dashboard

The dashboard is in `dashboard/Saudi_Budget_Analysis.pbix`. It has one page with seven visuals:

| Visual | Type | Content |
|---|---|---|
| Total expenditure | Card | Sum of expenditure |
| Total revenue | Card | Sum of revenue |
| Revenue vs. expenditure | Line chart | Comparison by year |
| Surplus/deficit | Line chart | Budget balance by year |
| Oil vs. non-oil revenue | Column chart | Revenue composition |
| Operating vs. capital spending | Clustered columns | Expenditure composition |
| Expenditure vs. revenue | Scatter (play axis) | Each year's movement on both axes |

To open it, download the file and open it with Power BI Desktop.

## Key Findings

![Revenue vs expenditure](images/revenue_vs_expenditure.png)

**1. The oil cycle drives the budget.** Revenue peaked in 2012 (about SAR 1.25 trillion) and then fell sharply as oil prices declined. Expenditure peaked in 2014 (about SAR 1.14 trillion).

![Budget balance](images/budget_balance.png)

**2. More deficits than surpluses.** The budget ran a surplus in 11 years and a deficit in 17. The largest surplus was in 2008 (about SAR 581 billion) and the largest deficit in 2015 (about SAR 389 billion). The cumulative deficit from 2014 to 2020 is roughly SAR 1.64 trillion.

![Revenue composition](images/revenue_composition.png)

**3. Gradual revenue diversification.** Oil's share of revenue peaked at 92.6% in 2011 and fell to 52.8% in 2020. Non-oil revenue rose from SAR 126.8 billion in 2014 to SAR 368.8 billion in 2020 (about 19.5% compound annual growth), its highest level in the dataset. Part of the drop in oil's share comes from oil revenue itself shrinking, not only from non-oil growth.

![Expenditure composition](images/expenditure_composition.png)

**4. Operating spending dominates.** Capital expenditure ranged from about 1% to 30% of total spending, peaking near 30% in 2009 and falling to about 14% in 2020, while operating expenditure stayed high and was less flexible on the way down.

## Repository Structure

```
.
├── README.md
├── data/
│   ├── data.xlsx
│   └── saudi_budget.db
├── notebook/
│   ├── saudi_budget_analysis.ipynb
│   ├── queries.sql
│   └── sql_analysis.py
├── dashboard/
│   └── Saudi_Budget_Analysis.pbix
└── images/
    ├── revenue_vs_expenditure.png
    ├── budget_balance.png
    ├── revenue_composition.png
    ├── revenue_forecast.png
    └── expenditure_composition.png
```

## Limitations

- The data is annual and ends in 2020, so it excludes the post-pandemic recovery and later years.
- Values are nominal (not inflation-adjusted), so comparisons across decades should be made with care.
- The original data source is not recorded in the files. Add a link here (for example, GASTAT or the Ministry of Finance).

## Future Work

- Update the data to the most recent years.
- Express figures as a share of GDP.
- Link oil revenue to oil prices, and replace the linear regression with a better model (e.g., ARIMA or an oil-price-driven model).
- Adjust values for inflation for a real-terms comparison.

## Tools

Power BI · Excel · Python (pandas / matplotlib / scikit-learn) · SQLite
