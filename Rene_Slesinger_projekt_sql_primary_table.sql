/*
 * Discord - rene69390
 */	
/*
 * TABULKA 1 - Sjednocení mezd a cen potravin v ČR pro společné roky (2006–2018) 
 */

SELECT * FROM czechia_price ORDER BY date_from;
SELECT * FROM czechia_payroll ORDER BY payroll_year;	
-- Ceny potravin a průměrných mezd se prolínají v letech 2006 - 2018.	


CREATE OR REPLACE TABLE t_Rene_Slesinger_project_SQL_primary_final AS
SELECT 
	cp.payroll_year AS rok,
	cpib.name AS nazev_odvetvi,
	cp.value AS prumerna_mzda_za_rok,
	cpc.name AS nazev_zbozi,
	cpc.price_value AS mnozstvi,
	cpc.price_unit AS jednotka,
	cpr.value AS prumerna_cena_produktu_za_rok,
	cpr.category_code AS kod_kategorie_zbozi
FROM (SELECT 
			value,
			industry_branch_code,
			payroll_year
		FROM czechia_payroll
		WHERE value_type_code = 5958 -- průměrná hrubá mzda na zaměstnace - kód 5958 převzat z tabulky czechia_payroll_value_type
			AND calculation_code = 100  -- kód 100 převzat z tabulky czechia_payroll_calculation
			AND value IS NOT NULL
			AND industry_branch_code IS NOT NULL
			AND payroll_year BETWEEN 2006 AND 2018) AS cp
LEFT JOIN 
		(SELECT 
			name,
			code
		FROM czechia_payroll_industry_branch) AS cpib 
ON cp.industry_branch_code = cpib.code
LEFT JOIN 
		(SELECT 
				value,
				category_code,
				date_from,
				region_code
			FROM czechia_price
			WHERE value IS NOT NULL
			AND region_code IS NULL) AS cpr
ON cp.payroll_year = year(cpr.date_from)
LEFT JOIN 
		(SELECT 
			name,
			code,
			price_unit,
			price_value
		FROM czechia_price_category) AS cpc 
ON cpr.category_code = cpc.code;

