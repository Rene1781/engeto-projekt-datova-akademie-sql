/*
 * 5. Má výše HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
 * projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */

-- VIEW HDP v ČR v letech 2006 - 2018
CREATE OR REPLACE VIEW v_Rene_Slesinger_project_hdp_cr_2006_2018 AS 
SELECT * FROM t_Rene_Slesinger_project_SQL_secondary_final
WHERE zeme = 'Czech Republic';


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


