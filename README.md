# Saudi Arabia Budget Analysis (1993 – 2020)

A data analysis project on Saudi Arabia's public finances, covering 28 years of revenues, expenditures, and budget surplus/deficit. It includes a Python notebook, a SQLite database, and an interactive Power BI dashboard.

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
│   └── saudi_budget_analysis.ipynb
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
