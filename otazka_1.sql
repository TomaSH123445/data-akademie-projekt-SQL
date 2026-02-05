-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
WITH mzdy AS (
  SELECT
    year,
    industry_branch_code,
    MAX(industry_branch_name) AS industry_branch_name,
    MAX(avg_wage_czk) AS prumerna_mzda
  FROM t_tomas_havelec_project_sql_primary_final
  WHERE industry_branch_code <> 'ALL'
  GROUP BY year, industry_branch_code
)
SELECT
  year,
  industry_branch_code,
  industry_branch_name,
  ROUND(prumerna_mzda, 2) AS prumerna_mzda,
  ROUND(LAG(prumerna_mzda) OVER (PARTITION BY industry_branch_code ORDER BY year), 2) AS predchozi_mzda,
  ROUND(
    (100 * (prumerna_mzda / NULLIF(LAG(prumerna_mzda) OVER (PARTITION BY industry_branch_code ORDER BY year), 0) - 1))::numeric,
    2
  ) AS mezirocni_zmena_procent
FROM mzdy
ORDER BY industry_branch_code, year;
