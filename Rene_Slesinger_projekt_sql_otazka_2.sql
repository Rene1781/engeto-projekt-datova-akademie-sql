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

