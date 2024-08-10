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
