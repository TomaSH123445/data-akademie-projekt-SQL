-- 5) Má HDP vliv na změny mezd a cen potravin (stejný / následující rok)?

WITH gdp AS (
  SELECT year, gdp_yoy_pct
  FROM t_tomas_havelec_project_sql_secondary_final
  WHERE country = 'Czech Republic'
),
mzdy AS (
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
  g.year,
  g.gdp_yoy_pct,
  y.rust_mezd_pct,
  y.rust_cen_pct,
  LEAD(y.rust_mezd_pct) OVER (ORDER BY g.year) AS rust_mezd_pct_pristi_rok,
  LEAD(y.rust_cen_pct)  OVER (ORDER BY g.year) AS rust_cen_pct_pristi_rok
FROM gdp g
JOIN yoy y USING (year)
ORDER BY g.year;
