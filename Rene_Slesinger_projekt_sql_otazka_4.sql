/*
 * 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

-- VIEW Průměrná mzda v ČR v letech 2006 - 2018 (průměr ze všech odvětví dohromady)
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_prumerna_mzda_cr_2006_2018 AS 
SELECT 
	nazev_odvetvi, -- sloupec nazev_odvetvi pro propojení v další tabulce
	rok, 
	round(avg(prumerna_mzda_za_rok_CZK)) AS prumerna_mzda_za_rok_CR_CZK
FROM v_Rene_Slesinger_project_prumerne_mzdy_podle_odvetvi_a_oboru
GROUP BY rok;


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


-- VIEW Půměrné ceny potravin v ČR v letech 2006 - 2018 (průměr ze všech kategorií dohromady)
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_prumerne_ceny_potravin_cr_2006_2018 AS 
SELECT 
	nazev_zbozi,	-- sloupec nazev_zbozi pro propojení v další tabulce
	rok,
	round(avg(prumerna_cena_produktu_za_rok), 2) AS prumerna_cena_produktu_za_rok_cr_czk
FROM v_Rene_Slesinger_project_rocni_prumerna_cena_potravin
GROUP BY rok;


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

