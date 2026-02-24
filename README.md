# SQL projekt – mzdy, ceny potravin a HDP

**Autor:** Tomas Havelec  
**Databaze:** PostgreSQL  

## Cíl projektu

Cílem tohoto projektu je připravit robustní analytický datový podklad umožňující objektivně posoudit vývoj dostupnosti základních potravin v České republice na základě průměrných příjmů obyvatel v čase. Analýza se zaměřuje na porovnání vývoje mezd a cen vybraných potravin v jednotném, časově porovnatelném období a na identifikaci dlouhodobých trendů v jejich dostupnosti. Součástí projektu je také vytvoření doplňkové datové tabulky zahrnující vybrané evropské státy, která obsahuje ukazatele HDP, Giniho koeficientu a velikosti populace ve stejném časovém období. Tento přehled slouží k zasazení výsledků za Českou republiku do širšího evropského kontextu a **odpovídá na pět výzkumných otázek** týkajících se vývoje mezd, cen potravin, kupní síly a možného vztahu k vývoji HDP v České republice a dalších evropských státech.

K tomu jsou vytvořeny dvě výsledné tabulky, nad kterými běží analytické dotazy:

1. `t_tomas_havelec_project_sql_primary_final` – mzdy a ceny potravin za Českou republiku na společném časovém intervalu.  
2. `t_tomas_havelec_project_sql_secondary_final` – makroekonomická data pro evropské státy (HDP, GINI, populace, meziroční růst HDP).

## Použité zdroje
- `czechia_payroll`, `czechia_payroll_value_type`, `czechia_payroll_unit`, `czechia_payroll_industry_branch`  
- `czechia_price`, `czechia_price_category`  
- `economies`, `countries`  


## Popis výsledných tabulek

### 1. `t_tomas_havelec_project_sql_primary_final`

**Zdroj:** `czechia_payroll` + `czechia_price`

**Sloupce:**
- `year` – kalendářní rok (společné roky mezd a cen)
- `industry_branch_code` – kód odvětví (nebo `ALL` pro celkový průměr)
- `industry_branch_name` – název odvětví
- `avg_wage_czk` – průměrná mzda (v Kč) pro dané odvětví a rok
- `category_code` – kód kategorie potraviny
- `category_name` – název kategorie potraviny
- `price_value` – množství jednotky v ceníku (např. 1, 0.5, 150…)
- `price_unit` – jednotka množství (např. `kg`, `l`, `g`, `ks`)
- `avg_price_czk` – průměrná cena potraviny (v Kč) pro daný rok (celá ČR)
- `units_affordable_for_avg_wage` – kolik jednotek dané potraviny lze koupit za průměrnou mzdu (`avg_wage_czk / avg_price_czk`)


### 2.`t_tomas_havelec_project_sql_secondary_final`

**Zdroj:** `economies` + `countries` (Evropa)

**Sloupce:**
- `country` – název státu
- `year` – kalendářní rok (stejné období jako v primární tabulce)
- `gdp` – hrubý domácí produkt (HDP)
- `gini` – GINI koeficient (příjmová nerovnost)
- `population` – počet obyvatel
- `gdp_yoy_pct` – meziroční změna HDP v % (pro první rok dané země může být `NULL`, protože není předchozí rok pro výpočet)
 

## Informace o výstupních datech a chybějících hodnotách

**Primární tabulka**

Primární tabulka je sestavená pouze pro roky 2006–2018, protože právě v tomto období existují v datové sadě czechia_price dostupná a srovnatelná data. Czechia_payroll sice mohou obsahovat i jiné roky, ale mimo uvedené období by už nešlo korektně dělat společné porovnání mezd a cen potravin, proto jsou roky sjednocené na průnik dostupných dat.

**Sekundární tabulka**

Sekundární tabulka má 585 řádků ( 45 zemí × 13 let, období 2006–2018). Kompletní jsou sloupce country, year a population, ale chybí část ekonomických ukazatelů: gdp je NULL v 37 záznamech, gini v 124 záznamech a gdp_yoy_pct v 39 záznamech (typicky u prvního dostupného roku nebo tam, kde chybí gdp pro výpočet meziroční změny). Z evropských entit se v tabulce vůbec nevyskytují Holy See, Northern Ireland a Svalbard and Jan Mayen, protože pro období 2006–2018 nemají v economies žádná data.

## Výzkumné otázky – slovní odpovědi

### Otázka 1  
**Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**  

Z výstupu dotazu vidíme, že většina odvětví vykazuje v čase kladný meziroční růst mezd. Mzdy tedy dlouhodobě rostou. V několika málo letech se však objevují odvětví s mírným poklesem mezd (např. Vzdělávání/2010 nebo Těžba a dobývání/2009,2013,2014,2016 ), což souvisí pravděpodobně s ekonomickými zpomaleními v těchto obdobích. Celkově lze říci, že trend mezd je rostoucí, ale rozhodně ne striktně monotonní. Některá odvětví v jednotlivých letech krátkodobě klesají.

### Otázka 2  
**Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?**  

Z tabulky `t_tomas_havelec_project_sql_primary_final` pro celkový průměr `ALL` vyplývá, že na začátku sledovaného období 2006 bylo možné za průměrnou mzdu koupit přibližně 1,466 litrů mléka a 1,312 kg chleba. Na konci období 2018 tato kupní síla vzrostla na zhruba 1,670 litrů mléka a 1,365 kg chleba. Kupní síla domácností u základních potravin se tedy v čase zvýšila, i když růst není u obou komodit nutně stejně rychlý.

### Otázka 3  
**Která kategorie potravin zdražuje nejpomaleji?**  

Analýza ročních průměrných cen podle kategorií ukazuje, že nejpomaleji zdražující kategorií je krystalový cukr, který má nejnižší průměrný meziroční růst cen v procentech (-1,92%). To znamená, že její cena rostla v čase stabilněji a méně dynamicky než u ostatních potravin. Ostatní kategorie vykazují výrazně vyšší průměrné tempo zdražování.

### Otázka 4  
**Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (o více než 10 p. b.)?**  

Výsledek dotazu srovnávající meziroční růst průměrné mzdy a růst průměrných cen potravin ukazuje, že takové roky neexistují.

### Otázka 5  
**Má výška HDP vliv na změny ve mzdách a cenách potravin?**  

V datech není vidět stabilní a jednoznačný vztah mezi růstem HDP a růstem mezd či cen potravin ani ve stejném roce, ani v roce následujícím. Např. v roce 2009 HDP výrazně kleslo (-4,66 %), ale mzdy dál rostly (+3,07 %) a ceny potravin naopak klesly (-6,41 %). Naopak v roce 2015 při silném růstu HDP (+5,39 %) ceny potravin klesaly (-0,55 %) a mzdy rostly jen mírně (+2,6 %). Celkově to spíš ukazuje, že mzdy i ceny potravin ovlivňují i jiné faktory než samotné HDP.


## Jak skripty používat

1. Spusť `primarni_tabulka.sql` – vytvoří tabulku `t_tomas_havelec_project_sql_primary_final`.  
2. Spusť `sekundarni_tabulka.sql` – vytvoří tabulku `t_tomas_havelec_project_sql_secondary_final`.  
3. Spusť jednotlivé dotazy `otazka_1_*.sql` až `otazka_5_*.sql` 
