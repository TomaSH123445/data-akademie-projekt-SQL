-- 2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?

WITH x AS (
  SELECT
    year,
    category_code,
    MAX(category_name) AS category_name,
    MAX(avg_wage_czk) AS prumerna_mzda,
    MAX(avg_price_czk) AS prumerna_cena,
    MAX(units_affordable_for_avg_wage) AS kusu_za_mzdu
  FROM t_tomas_havelec_project_sql_primary_final
  WHERE industry_branch_code = 'ALL'
    AND category_code IN (111301, 114201)
  GROUP BY year, category_code
)
SELECT
  year,
  ROUND(MAX(prumerna_mzda), 2) AS prumerna_mzda,
  ROUND(MAX(CASE WHEN category_code = 114201 THEN prumerna_cena END), 2) AS cena_mleka,
  ROUND(MAX(CASE WHEN category_code = 114201 THEN kusu_za_mzdu END), 1) AS litru_mleka_za_mzdu,
  ROUND(MAX(CASE WHEN category_code = 111301 THEN prumerna_cena END), 2) AS cena_chleba,
  ROUND(MAX(CASE WHEN category_code = 111301 THEN kusu_za_mzdu END), 1) AS kg_chleba_za_mzdu
FROM x
WHERE year IN (
  (SELECT MIN(year) FROM x),
  (SELECT MAX(year) FROM x)
)
GROUP BY year
ORDER BY year;
