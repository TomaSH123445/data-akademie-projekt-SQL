-- Která kategorie potravin zdražuje nejpomaleji (nejnižší meziroční nárůst)?
WITH ceny AS (
  SELECT
    year,
    category_code,
    MAX(category_name) AS category_name,
    MAX(avg_price_czk) AS prumerna_cena
  FROM t_tomas_havelec_project_sql_primary_final
  WHERE industry_branch_code = 'ALL'
  GROUP BY year, category_code
),
yoy AS (
  SELECT
    category_code,
    category_name,
    year,
    ROUND(
      (100 * (prumerna_cena / NULLIF(LAG(prumerna_cena) OVER (PARTITION BY category_code ORDER BY year), 0) - 1))::numeric,
      2
    ) AS mezirocni_rust_pct
  FROM ceny
)
SELECT
  category_code,
  category_name,
  ROUND(AVG(mezirocni_rust_pct)::numeric, 2) AS prumerny_mezirocni_rust_pct
FROM yoy
WHERE mezirocni_rust_pct IS NOT NULL
GROUP BY category_code, category_name
ORDER BY prumerny_mezirocni_rust_pct
LIMIT 1;
