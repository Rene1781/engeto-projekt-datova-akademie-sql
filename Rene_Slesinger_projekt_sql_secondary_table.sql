/* 
 * TABULKA 2 - Dodatečná data o dalších evropských státech (2006–2018) 
 */


CREATE OR REPLACE TABLE t_Rene_Slesinger_project_SQL_secondary_final AS
SELECT 
	c.country AS zeme,
	e.GDP AS HDP,
	e.YEAR AS rok
FROM economies AS e
JOIN countries AS c 
	ON e.country = c.country
	WHERE e.GDP IS NOT NULL
		AND e.country IS NOT NULL
		AND e.year BETWEEN 2006 AND 2018
		AND c.continent = 'Europe'
ORDER BY c.country, e.year;


