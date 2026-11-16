-- Saudi Arabia Budget Analysis (1993-2020): SQL analysis (SQLite)
-- Run through sql_analysis.py (or paste into any SQLite client). Table: public_finances_sql. View: budget. Values in million SAR.

-- Q1. Overview
SELECT COUNT(*)                       AS years,
       MIN(Year)                      AS first_year,
       MAX(Year)                      AS last_year,
       ROUND(SUM(Revenue)/1000.0)     AS total_revenue_bn,
       ROUND(SUM(Expenditure)/1000.0) AS total_expenditure_bn,
       ROUND(SUM(Balance)/1000.0)     AS cumulative_balance_bn
FROM budget;

-- Q2. Data quality: do the accounting identities hold? (max gap in million SAR)
SELECT MAX(ABS(Revenue - Oil_Revenue - NonOil_Revenue))     AS max_revenue_gap,
       MAX(ABS(Expenditure - Operating_Exp - Capital_Exp))  AS max_expenditure_gap,
       MAX(ABS(Balance - (Revenue - Expenditure)))          AS max_balance_gap
FROM budget;

-- Q3. Years when revenue exceeded SAR 1 trillion
SELECT Year, Revenue, Expenditure, Balance
FROM budget
WHERE Revenue > 1000000
ORDER BY Year DESC;

-- Q4. Surplus years vs deficit years
SELECT CASE WHEN Balance >= 0 THEN 'Surplus' ELSE 'Deficit' END AS outcome,
       COUNT(*)                          AS years,
       ROUND(SUM(Balance)/1000.0)        AS total_bn,
       ROUND(AVG(Balance)/1000.0)        AS avg_bn
FROM budget
GROUP BY outcome;

-- Q5. Largest surplus and largest deficit (UNION of two sorted sub-queries)
SELECT 'Largest surplus' AS record, Year, ROUND(Balance/1000.0) AS balance_bn
FROM (SELECT * FROM budget ORDER BY Balance DESC LIMIT 1)
UNION ALL
SELECT 'Largest deficit', Year, ROUND(Balance/1000.0)
FROM (SELECT * FROM budget ORDER BY Balance ASC LIMIT 1);

-- Q6. Oil share of revenue by year, with the change vs the previous year (LAG)
SELECT Year,
       ROUND(100.0 * Oil_Revenue / Revenue, 1) AS oil_share_pct,
       ROUND(100.0 * Oil_Revenue / Revenue
             - LAG(100.0 * Oil_Revenue / Revenue) OVER (ORDER BY Year), 1) AS change_pts
FROM budget
ORDER BY Year;

-- Q7. Peak and latest oil dependence
SELECT 'Peak oil share' AS record, Year, ROUND(100.0 * Oil_Revenue / Revenue, 1) AS oil_share_pct
FROM (SELECT * FROM budget ORDER BY 1.0 * Oil_Revenue / Revenue DESC LIMIT 1)
UNION ALL
SELECT 'Latest year', Year, ROUND(100.0 * Oil_Revenue / Revenue, 1)
FROM (SELECT * FROM budget ORDER BY Year DESC LIMIT 1);

-- Q8. Capital spending share of total expenditure, top 5 years (RANK)
WITH shares AS (
    SELECT Year, ROUND(100.0 * Capital_Exp / Expenditure, 1) AS capex_pct
    FROM budget
),
ranked AS (
    SELECT *, RANK() OVER (ORDER BY capex_pct DESC) AS rnk FROM shares
)
SELECT rnk, Year, capex_pct FROM ranked WHERE rnk <= 5 ORDER BY rnk;

-- Q9. Averages by period
SELECT CASE WHEN Year <= 1999 THEN '1) 1993-1999'
            WHEN Year <= 2009 THEN '2) 2000-2009'
            ELSE                   '3) 2010-2020' END AS period,
       COUNT(*)                             AS years,
       ROUND(AVG(Revenue)/1000.0)           AS avg_revenue_bn,
       ROUND(AVG(Expenditure)/1000.0)       AS avg_expenditure_bn,
       ROUND(AVG(Balance)/1000.0)           AS avg_balance_bn,
       ROUND(100.0 * AVG(Oil_Revenue * 1.0 / Revenue), 1) AS avg_oil_share_pct
FROM budget
GROUP BY period
ORDER BY period;

-- Q10. Revenue growth vs the previous year, five worst years (LAG + RANK)
WITH growth AS (
    SELECT Year, Revenue,
           ROUND(100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY Year))
                 / LAG(Revenue) OVER (ORDER BY Year), 1) AS growth_pct
    FROM budget
),
ranked AS (
    SELECT *, RANK() OVER (ORDER BY growth_pct ASC) AS rnk
    FROM growth WHERE growth_pct IS NOT NULL
)
SELECT rnk, Year, ROUND(Revenue/1000.0) AS revenue_bn, growth_pct
FROM ranked WHERE rnk <= 5 ORDER BY rnk;

-- Q11. Running total of the balance since 1993 (window computed over all years, then filtered)
WITH running AS (
    SELECT Year, Balance,
           SUM(Balance) OVER (ORDER BY Year) AS cumulative
    FROM budget
)
SELECT Year, ROUND(Balance/1000.0) AS balance_bn, ROUND(cumulative/1000.0) AS cumulative_bn
FROM running
WHERE Year IN (2008, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020)
ORDER BY Year;

-- Q12. The 2014-2020 deficit period and non-oil revenue growth (self-join)
SELECT ROUND((SELECT SUM(Balance) FROM budget WHERE Year BETWEEN 2014 AND 2020) / 1000.0) AS cumulative_balance_2014_2020_bn,
       ROUND(a.NonOil_Revenue / 1000.0, 1)  AS nonoil_2014_bn,
       ROUND(b.NonOil_Revenue / 1000.0, 1)  AS nonoil_2020_bn,
       ROUND(1.0 * b.NonOil_Revenue / a.NonOil_Revenue, 2) AS nonoil_multiple
FROM budget a JOIN budget b ON a.Year = 2014 AND b.Year = 2020;
