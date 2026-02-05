-- 4) Existuje rok, kdy meziroční nárůst cen potravin byl o >10 % vyšší než růst mezd?

WITH mzdy AS (
  SELECT year, MAX(avg_wage_czk) AS mzda
  FROM t_tomas_havelec_project_sql_primary_final
  WHERE industry_branch_code = 'ALL'
  GROUP BY year
),
ceny_potravin AS (
  SELECT year, AVG(avg_price_czk) AS cena_potravin
  FROM (
    SELECT year, category_code, MAX(avg_price_czk) AS avg_price_czk
    FROM t_tomas_havelec_project_sql_primary_final
    WHERE industry_branch_code = 'ALL'
    GROUP BY year, category_code
  ) t
  GROUP BY year
),
yoy AS (
  SELECT
    m.year,
    ROUND((100 * (m.mzda / NULLIF(LAG(m.mzda) OVER (ORDER BY m.year), 0) - 1))::numeric, 2) AS rust_mezd_pct,
    ROUND((100 * (c.cena_potravin / NULLIF(LAG(c.cena_potravin) OVER (ORDER BY c.year), 0) - 1))::numeric, 2) AS rust_cen_pct
  FROM mzdy m
  JOIN ceny_potravin c USING (year)
)
SELECT
  year,
  rust_mezd_pct,
  rust_cen_pct,
  ROUND((rust_cen_pct - rust_mezd_pct)::numeric, 2) AS rozdil_pct_bodu
FROM yoy
WHERE rust_mezd_pct IS NOT NULL
  AND rust_cen_pct IS NOT NULL
  AND (rust_cen_pct - rust_mezd_pct) > 10
ORDER BY rozdil_pct_bodu DESC, year;

