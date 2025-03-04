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

-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
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