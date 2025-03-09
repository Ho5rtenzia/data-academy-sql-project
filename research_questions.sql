-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
WITH salary_trend AS (
	SELECT 
		industry_name,
		payroll_date,
		ROUND(AVG(salary),2) AS average_salary,
		LAG(ROUND(AVG(salary),2)) OVER (PARTITION BY industry_name ORDER BY payroll_date) AS previous_year_salary
	FROM t_eva_vallusova_project_SQL_primary_final
	WHERE industry_name IS NOT NULL
	GROUP BY industry_name, payroll_date
)
SELECT 
		industry_name,
		payroll_date,
		average_salary,
		previous_year_salary,
		(average_salary-previous_year_salary) AS salary_change,
		CASE
			WHEN average_salary > previous_year_salary THEN 'rising'
			WHEN average_salary < previous_year_salary THEN 'falling'
			WHEN previous_year_salary IS NULL THEN 'N/A'
			ELSE 'equal'
		END AS trend
FROM salary_trend
ORDER BY industry_name, payroll_date;

-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
WITH salary_price AS (
	SELECT 
	    category_name,
	    payroll_date,
	    ROUND(AVG(salary), 2) AS avg_salary,
	    ROUND(AVG(price), 2) AS avg_price,
	    ROUND(AVG(salary) / AVG(price), 0) AS amount_can_buy,
	    RANK () OVER (PARTITION BY category_name ORDER BY payroll_date ASC) AS first_rank,
	    RANK () OVER (PARTITION BY category_name ORDER BY payroll_date DESC) AS last_rank
	FROM t_eva_vallusova_project_SQL_primary_final
	WHERE category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
	GROUP BY category_name, payroll_date
	)
SELECT
	category_name,
	payroll_date,
	avg_salary,
	avg_price,
	amount_can_buy,
	CASE 
		WHEN first_rank = 1 THEN 'first available period'
		WHEN last_rank = 1 THEN 'last available period'
	END AS period
FROM salary_price
WHERE first_rank = 1 OR last_rank = 1
ORDER BY category_name, payroll_date;

-- 3. Která kategorie potravin zdražuje nejpomaleji 
-- (je u ní nejnižší percentuální meziroční nárůst)?
WITH price_by_year AS (
	SELECT 
		YEAR(STR_TO_DATE(price_date_from, '%d.%m.%Y')) AS price_year,
		category_name, 
		ROUND(AVG(price), 2) AS avg_price
	FROM t_eva_vallusova_project_sql_primary_final
	GROUP BY category_name, price_year
),
price_change AS (
	SELECT 
		price_year,
		category_name,
		avg_price,
		LAG(avg_price) OVER (PARTITION BY category_name ORDER BY price_year) AS previous_year_price
	FROM price_by_year
),
percent_change_per_category AS (
	SELECT 
		category_name,
		ROUND(AVG((avg_price - previous_year_price) / previous_year_price) * 100, 2) AS avg_annual_percent_change
	FROM price_change
	WHERE previous_year_price IS NOT NULL
	GROUP BY category_name
)
SELECT 
	category_name,
	ABS(avg_annual_percent_change) AS lowest_avg_annual_percent_change
FROM percent_change_per_category
ORDER BY lowest_avg_annual_percent_change
LIMIT 1;

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd 
-- (větší než 10 %)?
WITH price_by_year AS (
	SELECT 
		YEAR(STR_TO_DATE(price_date_from, '%d.%m.%Y')) AS year_of_measurement,
		ROUND(AVG(price), 2) AS avg_price,
		ROUND(AVG(salary), 2) AS avg_salary
	FROM t_eva_vallusova_project_sql_primary_final
	GROUP BY year_of_measurement
),
change_of_measurement AS (
	SELECT 
		year_of_measurement,
		avg_price,
		LAG(avg_price) OVER (ORDER BY year_of_measurement) AS previous_year_price,
		avg_salary,
		LAG(avg_salary) OVER (ORDER BY year_of_measurement) AS previous_year_salary
	FROM price_by_year
),
percent_change_per_year AS (
	SELECT 
		year_of_measurement,
		ROUND(((avg_price-previous_year_price)/previous_year_price) * 100,2) AS avg_price_percent_change,
		ROUND(((avg_salary-previous_year_salary)/previous_year_salary) * 100,2) AS avg_salary_percent_change
	FROM change_of_measurement
	WHERE previous_year_price IS NOT NULL
		AND previous_year_salary IS NOT NULL
)
SELECT 
	year_of_measurement,
	avg_price_percent_change,
	avg_salary_percent_change,
	avg_price_percent_change - avg_salary_percent_change AS difference
FROM percent_change_per_year
ORDER BY difference DESC;


-- 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
WITH yearly_data AS(
	SELECT 
		tevp.payroll_date AS year_of_measurement,
		ROUND(AVG(tevp.salary),2) AS avg_salary,
		ROUND(AVG(tevp.price), 2) AS avg_price,
		GDP
	FROM t_eva_vallusova_project_sql_primary_final tevp
	JOIN t_eva_vallusova_project_sql_secondary_final tevs
		ON tevp.payroll_date = tevs.`year`
	WHERE tevs.country = 'Czech Republic'
	GROUP BY tevp.payroll_date
),
lagged_data AS (
	SELECT 
		year_of_measurement,
		avg_salary,
		avg_price,
		GDP,
		LAG(avg_salary) OVER (ORDER BY year_of_measurement) AS prev_salary,
		LAG(avg_price) OVER (ORDER BY year_of_measurement) AS prev_price,
		LAG(GDP) OVER (ORDER BY year_of_measurement) AS prev_gdp
	FROM yearly_data
)
SELECT 
	year_of_measurement,
	avg_salary,
	avg_price,
	GDP,
	ROUND(((avg_salary-prev_salary)/prev_salary) * 100,2) AS salary_growth,
	ROUND(((avg_price-prev_price)/prev_price) * 100,2) AS price_growth,
	ROUND(((GDP-prev_gdp)/prev_gdp) * 100,2) AS gdp_growth
FROM lagged_data;
