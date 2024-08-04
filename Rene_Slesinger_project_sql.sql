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
	


SELECT * FROM t_Rene_Slesinger_project_SQL_primary_final
ORDER BY rok, nazev_zbozi;


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

SELECT * FROM t_Rene_Slesinger_project_SQL_secondary_final;


/*
 * Výzkumné otázky
 */

/*
 * 1.	Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 */

-- VIEW Průměrné mzdy podle odvětví a oboru
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru AS 
SELECT 
	nazev_odvetvi,
	rok,
	round(avg(prumerna_mzda_za_rok)) AS prumerna_mzda_za_rok_CZK
FROM t_Rene_Slesinger_project_SQL_primary_final
GROUP BY nazev_odvetvi, rok
ORDER BY nazev_odvetvi;

SELECT * FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru;

-- VIEW Trend růstu mezd podle odvětví v průběhu let (počátek a konec období) v CZK a v procentech 
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_trend_rustu_mezd_podle_odvetvi_a_roku AS 
SELECT
	konecny_prumer.nazev_odvetvi, 
	pocatecni_prumer.rok AS pocatecni_rok,
	pocatecni_prumer.prumerna_mzda_za_rok_CZK AS pocatecni_mzda,
	konecny_prumer.rok AS konecny_rok,
	konecny_prumer.prumerna_mzda_za_rok_CZK AS konecna_mzda,
	konecny_prumer.prumerna_mzda_za_rok_CZK - pocatecni_prumer.prumerna_mzda_za_rok_CZK AS rozdil_mezd_v_czk,
	round(konecny_prumer.prumerna_mzda_za_rok_CZK * 100 / pocatecni_prumer.prumerna_mzda_za_rok_CZK, 2) - 100 AS rozdil_mezd_v_procentech,
	CASE
		WHEN konecny_prumer.prumerna_mzda_za_rok_CZK > pocatecni_prumer.prumerna_mzda_za_rok_CZK
			THEN 'Růst'
			ELSE 'Pokles'
	END AS trend_mezd
FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru AS konecny_prumer
JOIN v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru AS pocatecni_prumer
	ON konecny_prumer.nazev_odvetvi = pocatecni_prumer.nazev_odvetvi
	AND konecny_prumer.rok = pocatecni_prumer.rok +1
ORDER BY nazev_odvetvi;

SELECT * FROM v_Rene_Slesinger_project_trend_rustu_mezd_podle_odvetvi_a_roku;
-- Mzdy v uvedených odvětvích celkově od roku 2006 do roku 2018 rostou,
-- nicméně v některých letech byl zaznamenán meziroční pokles - viz dále.

-- Meziroční pokles mezd
SELECT *
FROM v_Rene_Slesinger_project_trend_rustu_mezd_podle_odvetvi_a_roku
WHERE trend_mezd = 'Pokles'
ORDER BY rozdil_mezd_v_procentech;
-- Největší meziroční pokles zaznamenalo odvětví Peněžnictví a pojišťovnictví v roce 2013, 
-- kdy se průměrná mzda snížila o -9 % ze 49 707 Kč v roce 2012 na 45 234 Kč v roce 2013.
-- Pokles mzdy byl zaznamenán ve 23 případech.

-- Průměrná měsíční mzda (porovnání podle odvětví v letech 2006 a 2018)
SELECT *
FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru
WHERE rok IN (2006, 2018);

-- Mzdový nárůst celkem od roku 2006 do roku 2018 podle odvětví v procentech  
SELECT
	konecny_prumer.nazev_odvetvi, 
	pocatecni_prumer.rok AS pocatecni_rok,
	pocatecni_prumer.prumerna_mzda_za_rok_CZK AS pocatecni_mzda,
	konecny_prumer.rok AS konecny_rok,
	konecny_prumer.prumerna_mzda_za_rok_CZK AS konecna_mzda,
	konecny_prumer.prumerna_mzda_za_rok_CZK - pocatecni_prumer.prumerna_mzda_za_rok_CZK AS rozdil_mezd_v_czk,
	round(konecny_prumer.prumerna_mzda_za_rok_CZK * 100 / pocatecni_prumer.prumerna_mzda_za_rok_CZK, 2) - 100 AS rozdil_mezd_v_procentech
FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru AS konecny_prumer
JOIN v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru AS pocatecni_prumer
	ON konecny_prumer.nazev_odvetvi = pocatecni_prumer.nazev_odvetvi
		WHERE pocatecni_prumer.rok = 2006 
			AND konecny_prumer.rok = 2018
ORDER BY round(konecny_prumer.prumerna_mzda_za_rok_CZK * 100 / pocatecni_prumer.prumerna_mzda_za_rok_CZK, 2) - 100 DESC;
-- Nejvyšší nárůst mezd byl v odvětví Zdravotní a sociální péče, kde byla v roce 2018 průměrná mzda o téměř 76 % vyšší než v roce 2006. 
-- Nejnižší nárůst mezd byl v odvětví Peněžnictví a pojišťovnictví, kde byla v roce 2018 průměrná mzda o zhruba 35,5 % vyšší než v roce 2006.

/*
 * 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 */

-- Kupní síla v ČR v letech 2006 a 2018 vzhledem k cenám chleba a mléka.
SELECT
	nazev_zbozi, jednotka, mnozstvi, rok,
	round(avg(prumerna_cena_produktu_za_rok), 2) AS prumerna_cena_produktu_za_rok,
	round(avg(prumerna_mzda_za_rok), 2) AS prumerna_mzda_za_rok,
	round((round(avg(prumerna_mzda_za_rok), 2)) / (round(avg(prumerna_cena_produktu_za_rok), 2))) AS prumerna_kupni_sila
FROM t_Rene_Slesinger_project_SQL_primary_final
WHERE rok IN(2006, 2018)
	AND nazev_zbozi IN('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
GROUP BY nazev_zbozi, rok;
-- V roce 2006 bylo za průměrnou cenu chleba 16,12 Kč a průměrnou mzdu 20 342,38 Kč možné koupit 1 262 kg chleba a 1 409 l mléka za cenu 14,44 Kč. 
-- V roce 2018 bylo za cenu 24,24 Kč a průměrnou mzdu 31 980,26 Kč možné nakoupit 1 319 kg chleba a 1 614 l mléka za průměrnou cenu 19,82 Kč. 

-- Kupní síla v ČR v letech 2006 a 2018 vzhledem k cenám chleba a mléka podle odvětví
SELECT
	nazev_odvetvi,
	nazev_zbozi, jednotka, mnozstvi, rok,
	round(avg(prumerna_cena_produktu_za_rok), 2) AS prumerna_cena_produktu_za_rok,
	round(avg(prumerna_mzda_za_rok), 2) AS prumerna_mzda_za_rok,
	round((round(avg(prumerna_mzda_za_rok), 2)) / (round(avg(prumerna_cena_produktu_za_rok), 2))) AS prumerna_kupni_sila
FROM t_Rene_Slesinger_project_SQL_primary_final
WHERE rok IN(2006, 2018)
	AND nazev_zbozi IN('Mléko polotučné pasterované',  'Chléb konzumní kmínový')
GROUP BY nazev_odvetvi, nazev_zbozi, rok;

-- Kupní síla obyvatel pro ČR v letech 2006 a 2018 vzhledem k cenám chleba a mléka
-- podle kategorie potravin a odvětví, seřazené podle kupní síly
SELECT
	nazev_zbozi, jednotka, mnozstvi, rok,
	round(avg(prumerna_cena_produktu_za_rok), 2) AS prumerna_cena_produktu_za_rok,
	round(avg(prumerna_mzda_za_rok), 2) AS prumerna_mzda_za_rok,
	round((round(avg(prumerna_mzda_za_rok), 2)) / (round(avg(prumerna_cena_produktu_za_rok), 2))) AS prumerna_kupni_sila,
	nazev_odvetvi
FROM t_Rene_Slesinger_project_SQL_primary_final
WHERE rok IN(2006, 2018)
	AND nazev_zbozi IN('Mléko polotučné pasterované',  'Chléb konzumní kmínový')
GROUP BY nazev_zbozi, rok, nazev_odvetvi
ORDER BY round((round(avg(prumerna_mzda_za_rok), 2)) / (round(avg(prumerna_cena_produktu_za_rok), 2))) DESC;


/*
 * 3.	Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší procentuální meziroční nárůst)?
 */

-- VIEW Roční průměrná cena potravin
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_rocni_prumerna_cena_potravin AS 
SELECT 
	DISTINCT nazev_zbozi,
	mnozstvi, 
	jednotka, 
	rok, 
	round(avg(prumerna_cena_produktu_za_rok), 2) AS prumerna_cena_produktu_za_rok
FROM t_Rene_Slesinger_project_SQL_primary_final
GROUP BY nazev_zbozi, rok;

SELECT * FROM v_Rene_Slesinger_project_rocni_prumerna_cena_potravin;

-- VIEW Cenový trend sledovaných potravin od roku 2006 do roku 2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_cenovy_trend_potravin AS 
SELECT 
	DISTINCT pocatecni_rok.nazev_zbozi, 
	pocatecni_rok.mnozstvi,
	pocatecni_rok.jednotka,
	pocatecni_rok.rok AS pocatecni_rok,
	pocatecni_rok.prumerna_cena_produktu_za_rok AS pocatecni_cena,
	konecny_rok.rok AS konecny_rok,
	konecny_rok.prumerna_cena_produktu_za_rok AS konecna_cena, 
	konecny_rok.prumerna_cena_produktu_za_rok - pocatecni_rok.prumerna_cena_produktu_za_rok AS rozdil_cen_v_czk,
	round((konecny_rok.prumerna_cena_produktu_za_rok - pocatecni_rok.prumerna_cena_produktu_za_rok) / pocatecni_rok.prumerna_cena_produktu_za_rok * 100, 2) AS rozdil_cen_v_procentech,
	CASE
		WHEN konecny_rok.prumerna_cena_produktu_za_rok > pocatecni_rok.prumerna_cena_produktu_za_rok
		THEN 	'Růst'
		ELSE 'Pokles'
	END AS cenovy_trend
FROM v_Rene_Slesinger_project_rocni_prumerna_cena_potravin AS pocatecni_rok
JOIN v_Rene_Slesinger_project_rocni_prumerna_cena_potravin AS konecny_rok 
	ON pocatecni_rok.nazev_zbozi = konecny_rok.nazev_zbozi
		AND konecny_rok.rok = pocatecni_rok.rok+1
ORDER BY nazev_zbozi, pocatecni_rok.rok;

SELECT * FROM v_Rene_Slesinger_project_cenovy_trend_potravin;

-- Průměrný meziroční nárůst cen potravin mezi roky 2006 - 2018
SELECT 
	pocatecni_rok,
	max(konecny_rok) AS konecny_rok,
	nazev_zbozi,
	round(avg(rozdil_cen_v_procentech), 2) AS prumerny_mezirocni_narust_cen_potravin_v_procentech
FROM v_Rene_Slesinger_project_cenovy_trend_potravin
GROUP BY nazev_zbozi
ORDER BY round(avg(rozdil_cen_v_procentech), 2);
-- Krystalový cukr patří mezi potraviny, jejichž cena se dokonce ve sledovaném období snížila, a to průměrně o -1,92 %. 
-- V období od roku 2006 do roku 2018 se průměrná cena za 1 kg krystalového cukru postupně zvyšovala a klesala z původních 21,92 Kč v roce 2006, 
-- na konečných 15,75 Kč v roce 2018. Na druhé straně, největší meziroční procentuální nárůst byl zaznamenán u paprik. 
-- Jejich cena se zvyšovala průměrně  o 7,29 %.

-- Nejvyšší procentuální nárůst/pokles ceny
SELECT * FROM v_Rene_Slesinger_project_cenovy_trend_potravin
ORDER BY rozdil_cen_v_procentech DESC;

-- Nejvyšší procentuální nárůst/pokles ceny v procentech
SELECT * FROM v_Rene_Slesinger_project_cenovy_trend_potravin
ORDER BY rozdil_cen_v_procentech;
-- K nejvyššímu meziročnímu zdražení v období let 2006 až 2018 došlo u paprik mezi lety 2006 až 2007 o 94,82%, 
-- a naopak nejvíce zlevnila meziročně rajská jablka červená kulatá o -30,28%, bylo to rovněž v letech 2006 až 2007.

-- VIEW Průměrné ceny potravin - porovnání roků 2006 a 2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_porovnani_cen_potravin_2006_2018 AS 
SELECT 
	pocatecni_rok.nazev_zbozi,
	pocatecni_rok.mnozstvi,
	pocatecni_rok.jednotka,
	pocatecni_rok.rok AS pocatecni_rok,
	pocatecni_rok.prumerna_cena_produktu_za_rok AS pocatecni_cena,
	konecny_rok.rok AS konecny_rok,
	konecny_rok.prumerna_cena_produktu_za_rok AS konecna_cena,
	konecny_rok.prumerna_cena_produktu_za_rok - pocatecni_rok.prumerna_cena_produktu_za_rok AS rozdil_cen_v_czk,
	round((konecny_rok.prumerna_cena_produktu_za_rok - pocatecni_rok.prumerna_cena_produktu_za_rok) / pocatecni_rok.prumerna_cena_produktu_za_rok *100, 2) AS rozdil_cen_v_procentech
FROM v_Rene_Slesinger_project_rocni_prumerna_cena_potravin AS pocatecni_rok
JOIN v_Rene_Slesinger_project_rocni_prumerna_cena_potravin AS konecny_rok
	ON pocatecni_rok.nazev_zbozi = konecny_rok.nazev_zbozi
		WHERE pocatecni_rok.rok = 2006
			AND konecny_rok.rok = 2018;
		
SELECT * FROM v_Rene_Slesinger_project_porovnani_cen_potravin_2006_2018
ORDER BY rozdil_cen_v_procentech DESC;
-- Nejvyšší procentuální nárůst ceny potravin, při porovnání roku 2006 a 2018, byl zaznamenán u másla, navýšení o 98,38 %. 
-- Následují vaječné těstoviny s 83,45 % a paprika s 71,25 %. K výraznému zlevnění v období let 2006 až 2018 došlo u krystalového cukru 
-- a rajských jablek červených kulatých, s poklesem cen o -27,52 % a -23,07 %.


/*
 * 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

SELECT * FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru;

-- VIEW Průměrná mzda v ČR v letech 2006 - 2018 (průměr ze všech odvětví dohromady)
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_prumerna_mzda_cr_2006_2018 AS 
SELECT 
	nazev_odvetvi, -- sloupec nazev_odvetvi pro propojení v další tabulce
	rok, 
	round(avg(prumerna_mzda_za_rok_CZK)) AS prumerna_mzda_za_rok_CR_CZK
FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru
GROUP BY rok;

SELECT * FROM v_Rene_Slesinger_project_prumerna_mzda_cr_2006_2018;

-- VIEW Trend vývoje růstu mezd v ČR v letech 2006 - 2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_trend_vyvoje_rustu_mezd_cr_2006_2018 AS 
SELECT
	pmcr1.rok AS pocatecni_rok, 
	pmcr1.prumerna_mzda_za_rok_CR_CZK AS pocatecni_mzda,
	pmcr2.rok AS konecny_rok,
	pmcr2.prumerna_mzda_za_rok_CR_CZK AS konecna_mzda,
	round((pmcr2.prumerna_mzda_za_rok_CR_CZK - pmcr1.prumerna_mzda_za_rok_CR_CZK) / pmcr1.prumerna_mzda_za_rok_CR_CZK * 100, 2) AS rozdil_mezd_v_procentech
FROM v_Rene_Slesinger_project_prumerna_mzda_cr_2006_2018 AS pmcr1
JOIN v_Rene_Slesinger_project_prumerna_mzda_cr_2006_2018 AS pmcr2
	ON pmcr2.nazev_odvetvi = pmcr1.nazev_odvetvi 
		AND pmcr2.rok = pmcr1.rok + 1;

SELECT * FROM v_Rene_Slesinger_project_trend_vyvoje_rustu_mezd_cr_2006_2018;

-- VIEW Půměrné ceny potravin v ČR v letech 2006 - 2018 (průměr ze všech kategorií dohromady)
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_prumerne_ceny_potravin_cr_2006_2018 AS 
SELECT 
	nazev_zbozi,	-- sloupec nazev_zbozi pro propojení v další tabulce
	rok,
	round(avg(prumerna_cena_produktu_za_rok), 2) AS prumerna_cena_produktu_za_rok_cr_czk
FROM v_Rene_Slesinger_project_rocni_prumerna_cena_potravin
GROUP BY rok;

SELECT * FROM v_Rene_Slesinger_project_prumerne_ceny_potravin_cr_2006_2018;

-- VIEW Trend vývoje růstu cen potravin v ČR v letech 2006 - 2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_trend_vyvoje_cen_potravin_cr_2006_2018 AS 
SELECT 
	pcp1.rok AS pocatecni_rok, 
	pcp1.prumerna_cena_produktu_za_rok_cr_czk AS pocatecni_cena, 
	pcp2.rok AS konecny_rok, 
	pcp2.prumerna_cena_produktu_za_rok_cr_czk AS konecna_cena,
	pcp2.prumerna_cena_produktu_za_rok_cr_czk - pcp1.prumerna_cena_produktu_za_rok_cr_czk AS rozdil_cen_v_czk,
	round(avg(pcp2.prumerna_cena_produktu_za_rok_cr_czk - pcp1.prumerna_cena_produktu_za_rok_cr_czk) / pcp1.prumerna_cena_produktu_za_rok_cr_czk * 100, 2) AS rozdil_cen_v_procentech
FROM v_Rene_Slesinger_project_prumerne_ceny_potravin_cr_2006_2018 AS pcp1
JOIN v_Rene_Slesinger_project_prumerne_ceny_potravin_cr_2006_2018 AS pcp2 
	ON pcp2.nazev_zbozi = pcp1.nazev_zbozi
		AND pcp2.rok = pcp1.rok + 1
GROUP BY pcp1.rok;

-- VIEW Porovnání meziročního nárůstu průměrných cen a mezd v ČR
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_porovnani_narustu_cen_a_mezd_v_CR AS 
SELECT 
	tvcp.pocatecni_rok, 
	tvrm.konecny_rok,
	tvrm.rozdil_mezd_v_procentech,
	tvcp.rozdil_cen_v_procentech,
	tvcp.rozdil_cen_v_procentech - tvrm.rozdil_mezd_v_procentech AS rozdil_cen_a_mezd
FROM v_Rene_Slesinger_project_trend_vyvoje_cen_potravin_cr_2006_2018  AS tvcp
JOIN v_Rene_Slesinger_project_trend_vyvoje_rustu_mezd_cr_2006_2018 AS tvrm 
	ON tvrm.pocatecni_rok = tvcp.pocatecni_rok
	GROUP BY tvcp.pocatecni_rok
ORDER BY tvcp.rozdil_cen_v_procentech DESC;

SELECT * FROM v_Rene_Slesinger_project_porovnani_narustu_cen_a_mezd_v_CR
ORDER BY rozdil_cen_a_mezd DESC;
-- V žádném ze sledovaných roků, nebyl meziroční nárůst cen potravin vyšší o více než 10 % než růst mezd. 
-- V roce 2013 byl zaznamenán nejvyšší rozdíl mezi nárůstem cen a mezd, a to ve výši 6,66 %.
-- V tomto roce se ceny potravin oproti roku předchozímu zvýšily o 5,1 %, zatímco mzdy poklesly o -1,56 %.  
-- Největší meziroční nárůst cen potravin byl zaznamenán v roce 2017, a to ve výši 9,63 %. 



/*
 * 5. Má výše HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
 * projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */

-- VIEW HDP v ČR v letech 2006 - 2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_hdp_cr_2006_2018 AS 
SELECT * FROM t_Rene_Slesinger_project_SQL_secondary_final
WHERE zeme = 'Czech Republic';

SELECT * FROM v_Rene_Slesinger_project_hdp_cr_2006_2018;

-- VIEW HDP meziroční vývoj
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_hdp_mezirocni_vyvoj_cr_2006_2018 AS 
SELECT 
	hdp1.rok AS pocatecni_rok, 
	hdp1.HDP AS pocatecni_HDP, 
	hdp2.rok AS konecny_rok, 
	hdp2.HDP AS konecne_HDP,
	round(avg(hdp2.HDP - hdp1.HDP) / hdp1.HDP * 100, 2) AS rozdil_HDP_v_procentech
FROM v_Rene_Slesinger_project_hdp_cr_2006_2018 AS hdp1
JOIN v_Rene_Slesinger_project_hdp_cr_2006_2018 AS hdp2
	ON hdp2.zeme = hdp1.zeme
		AND hdp2.rok = hdp1.rok + 1
GROUP BY hdp1.rok;

SELECT * FROM v_Rene_Slesinger_project_hdp_mezirocni_vyvoj_cr_2006_2018;

-- VIEW Meziroční vývoj cen potravin, mezd a HDP v ČR 2006-2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_mezirocni_vyvoj_cen_mezd_hdp AS 
SELECT 
	hdp.pocatecni_rok, 
	hdp.konecny_rok, 
	ceny.rozdil_cen_v_procentech, 
	mzdy.rozdil_mezd_v_procentech, 
	hdp.rozdil_HDP_v_procentech
FROM v_Rene_Slesinger_project_hdp_mezirocni_vyvoj_cr_2006_2018 AS hdp
JOIN v_Rene_Slesinger_project_trend_vyvoje_rustu_mezd_cr_2006_2018 AS mzdy
	ON mzdy.pocatecni_rok = hdp.pocatecni_rok
JOIN v_Rene_Slesinger_project_trend_vyvoje_cen_potravin_cr_2006_2018 AS ceny 
	ON ceny.pocatecni_rok = hdp.pocatecni_rok;

SELECT * FROM v_Rene_Slesinger_project_mezirocni_vyvoj_cen_mezd_hdp;


-- Průměr meziročního růstu cen, mezd a HDP za celé období
SELECT 
	pocatecni_rok,
	max(konecny_rok) AS konecny_rok,
	round(avg(rozdil_cen_v_procentech), 2) AS prumerny_rust_cen_v_procentech, 
	round(avg(rozdil_mezd_v_procentech), 2) AS prumerny_rust_mezd_v_procentech, 
	round(avg(rozdil_HDP_v_procentech), 2) AS prumerny_rust_HDP_v_procentech
FROM v_Rene_Slesinger_project_mezirocni_vyvoj_cen_mezd_hdp;

-- Nárůst cen, mezd a HDP za celé období
SELECT 
	pocatecni_rok,
	max(konecny_rok) AS konecny_rok,
	round(sum(rozdil_cen_v_procentech), 2) AS prumerny_rust_cen_v_procentech, 
	round(sum(rozdil_mezd_v_procentech), 2) AS prumerny_rust_mezd_v_procentech, 
	round(sum(rozdil_HDP_v_procentech), 2) AS prumerny_rust_HDP_v_procentech
FROM v_Rene_Slesinger_project_mezirocni_vyvoj_cen_mezd_hdp;

-- Na základě analýzy průměrného růstu cen potravin, mezd a HDP v letech 2006–2018 nelze s jistotou potvrdit danou hypotézu. 
-- I když existuje určitá závislost, není pravidelná ani není jednoznačná pro všechny roky.
-- Například v roce 2015 je patrný výrazný růst HDP o 5,39 %, ale průměrné ceny potravin ve stejném i v následujícím roce klesaly. 
-- Na druhé straně v roce 2012 došlo ke snížení HDP, ale ceny potravin i mzdy v následujících letech rostly. 
-- V roce 2013 je vidět menší pokles HDP o -0,05 %, ale ceny potravin stouply a mzdy klesly. 
-- V roce 2009 došlo k výraznému poklesu HDP o -4,66 %, ale ceny potravin se naopak snížily a mzdy rostly.
-- Z dostupných dat lze tedy vyvodit, že výška HDP nemá jednoznačný vliv na změny cen potravin nebo platů. 
-- Průměrné ceny potravin, stejně jako průměrné mzdy, mohou stoupat i klesat nezávisle na vývoji HDP. 
-- V období od roku 2006 do 2018 převládaly mezi všemi sledovanými kategoriemi hodnoty meziročního růstu nad jejich poklesem. 
-- V případě HDP došlo ke třem meziročním poklesům, ceny potravin klesly ve třech případech a mzdy klesly pouze v jednom roce. 
-- Průměrná roční rychlost růstu HDP mezi lety 2006 a 2018 byla 2,13 % a celkový nárůst za toto období činil 25,51 %. 
-- Ceny potravin stoupaly průměrně o 2,87 % ročně a celkově se zvýšily o 34,44 %. 
-- Mzdy pak rostly v průměru o 3,88 % ročně, celkově pak vzrostly o 46,22 %.


