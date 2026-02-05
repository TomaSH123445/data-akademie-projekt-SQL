-- ==============================================
-- Autor: Tomáš Havelec
-- ==============================================

-- 1) Primární tabulka
CREATE TABLE t_tomas_havelec_project_sql_primary_final AS
WITH wage_type AS (e
    SELECT vt.code AS value_type_code
    FROM czechia_payroll cp
    JOIN czechia_payroll_value_type vt ON vt.code = cp.value_type_code
    WHERE cp.value IS NOT NULL
      AND vt.name ILIKE '%mzda%'
    GROUP BY vt.code
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
wage_unit_pref AS (
    SELECT cp.unit_code
    FROM czechia_payroll cp
    JOIN czechia_payroll_unit u ON u.code = cp.unit_code
    WHERE cp.value IS NOT NULL
      AND cp.value_type_code = (SELECT value_type_code FROM wage_type)
      AND u.name ILIKE '%Kč%'
    GROUP BY cp.unit_code
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
wage_unit_any AS (
    SELECT cp.unit_code
    FROM czechia_payroll cp
    WHERE cp.value IS NOT NULL
      AND cp.value_type_code = (SELECT value_type_code FROM wage_type)
    GROUP BY cp.unit_code
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
wage_unit AS (
    SELECT COALESCE(
      (SELECT unit_code FROM wage_unit_pref),
      (SELECT unit_code FROM wage_unit_any)
    ) AS unit_code
),
wages_by_calc AS (
    SELECT
        cp.payroll_year::int AS year,
        cp.industry_branch_code::text AS industry_branch_code,
        calc.name AS calculation_name,
        AVG(cp.value::numeric) AS avg_wage_czk
    FROM czechia_payroll cp
    LEFT JOIN czechia_payroll_calculation calc ON calc.code = cp.calculation_code
    WHERE cp.value IS NOT NULL
      AND cp.industry_branch_code IS NOT NULL
      AND cp.value_type_code = (SELECT value_type_code FROM wage_type)
      AND cp.unit_code       = (SELECT unit_code FROM wage_unit)
    GROUP BY cp.payroll_year, cp.industry_branch_code, calc.name
),
wages_industry AS (
    -- preferuj "přepočtený", když není, vezmi "fyzický", když ani to není, vezmi jakýkoliv
    SELECT
      year,
      industry_branch_code,
      COALESCE(
        MAX(avg_wage_czk) FILTER (WHERE calculation_name ILIKE '%přepočten%'),
        MAX(avg_wage_czk) FILTER (WHERE calculation_name ILIKE '%fyzick%'),
        MAX(avg_wage_czk)
      ) AS avg_wage_czk
    FROM wages_by_calc
    GROUP BY year, industry_branch_code
),
wages_named AS (
    SELECT
      w.year,
      w.industry_branch_code,
      ib.name AS industry_branch_name,
      w.avg_wage_czk
    FROM wages_industry w
    JOIN czechia_payroll_industry_branch ib
      ON ib.code::text = w.industry_branch_code
),
wages_all AS (
    SELECT
      year,
      'ALL'::text AS industry_branch_code,
      'Celkem (vsechna odvetvi)'::text AS industry_branch_name,
      AVG(avg_wage_czk) AS avg_wage_czk
    FROM wages_named
    GROUP BY year
),
wages AS (
    SELECT * FROM wages_named
    UNION ALL
    SELECT * FROM wages_all
),
prices AS (
    SELECT
        EXTRACT(YEAR FROM p.date_from)::int AS year,
        p.category_code::int AS category_code,
        pc.name AS category_name,
        pc.price_value::numeric AS price_value,
        pc.price_unit::text AS price_unit,
        AVG(p.value::numeric) AS avg_price_czk
    FROM czechia_price p
    JOIN czechia_price_category pc ON pc.code = p.category_code
    WHERE p.value IS NOT NULL
      AND p.region_code IS NULL
    GROUP BY
        EXTRACT(YEAR FROM p.date_from)::int,
        p.category_code,
        pc.name,
        pc.price_value,
        pc.price_unit
),
common_years AS (
    SELECT year FROM (SELECT DISTINCT year FROM wages) w
    INTERSECT
    SELECT year FROM (SELECT DISTINCT year FROM prices) p
)
SELECT
    cy.year,
    w.industry_branch_code,
    w.industry_branch_name,
    w.avg_wage_czk,
    p.category_code,
    p.category_name,
    p.price_value,
    p.price_unit,
    p.avg_price_czk,
    ROUND((w.avg_wage_czk / NULLIF(p.avg_price_czk, 0))::numeric, 2) AS units_affordable_for_avg_wage
FROM common_years cy
JOIN wages  w ON w.year = cy.year
JOIN prices p ON p.year = cy.year
ORDER BY cy.year, w.industry_branch_code, p.category_code;

-- 2) Sekundární tabulka
CREATE TABLE t_tomas_havelec_project_sql_secondary_final AS
WITH years AS (
  SELECT DISTINCT year FROM t_tomas_havelec_project_sql_primary_final
),
europe AS (
  SELECT
    TRIM(e.country)::text AS country,
    e.year::int AS year,
    e.gdp::numeric AS gdp,
    e.gini::numeric AS gini,
    e.population::numeric AS population,
    ROUND(
      (100 * (e.gdp / NULLIF(LAG(e.gdp) OVER (PARTITION BY TRIM(e.country) ORDER BY e.year), 0) - 1))::numeric,
      2
    ) AS gdp_yoy_pct
  FROM economies e
  JOIN countries c ON TRIM(c.country) = TRIM(e.country)
  WHERE TRIM(c.continent) = 'Europe'
)
SELECT eu.*
FROM europe eu
JOIN years y ON y.year = eu.year
ORDER BY eu.country, eu.year;
