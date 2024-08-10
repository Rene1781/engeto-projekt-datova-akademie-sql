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

