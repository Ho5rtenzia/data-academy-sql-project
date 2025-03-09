-- Vytvoreni 1. tabulky
CREATE TABLE IF NOT EXISTS t_eva_vallusova_project_SQL_primary_final AS
	SELECT
		cpib.name AS industry_name,
		cpc.name AS category_name,
		cpa.value AS salary,
		cpr.value AS price,
		cpa.payroll_year AS payroll_date,
		date_format(cpr.date_from, '%d.%m.%Y') AS price_date_from,
		date_format(cpr.date_to, '%d.%m.%Y') AS price_date_to,
		cr.name AS region
	FROM czechia_payroll cpa 
	JOIN czechia_price cpr
		ON cpa.payroll_year = YEAR(cpr.date_from)
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON cpib.code = cpa.industry_branch_code 
	LEFT JOIN czechia_price_category cpc 
		ON cpc.code = cpr.category_code 
	LEFT JOIN czechia_region cr 
		ON cr.code = cpr.region_code 
	WHERE cpa.value_type_code = 5958
	ORDER BY payroll_date DESC;

-- Vytvoreni 2. tabulky
CREATE TABLE IF NOT EXISTS t_eva_vallusova_project_SQL_secondary_final AS
SELECT 
	e.country,
	e.`year`,
	e.GDP,
	e.population,
	e.gini
FROM economies e
JOIN countries c 
	ON 	e.country = c.country 
WHERE c.continent = 'Europe'
	AND e.`year` BETWEEN 2009 AND 2018
ORDER BY e.`year` DESC;


