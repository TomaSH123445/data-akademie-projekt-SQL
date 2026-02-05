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

- `year` – kalendářní rok  
- `industry_code` – kód odvětví (nebo `ALL` pro celkový průměr)  
- `industry_name` – název odvětví  
- `avg_wage` – průměrná hrubá mzda na zaměstnance v daném odvětví a roce  
- `avg_food_price` – nevážený průměr cen všech potravin v daném roce  
- `milk_price` – průměrná cena litru mléka  
- `bread_price` – průměrná cena kilogramu chleba  
- `liters_milk` – kolik litrů mléka lze koupit za průměrnou mzdu  
- `kg_bread` – kolik kilogramů chleba lze koupit za průměrnou mzdu  

### 2. `t_tomas_havelec_project_sql_secondary_final`

**Zdroj:** `economies` + `countries` (Evropa)

**Sloupce:**

- `country` – název státu  
- `year` – kalendářní rok  
- `gdp` – hrubý domácí produkt  
- `gini` – koeficient příjmové nerovnosti  
- `population` – počet obyvatel  
- `gdp_yoy_pct` – meziroční růst HDP v %  
- `region`, `subregion` – geografická klasifikace v Evropě  

## Informace o výstupních datech a chybějících hodnotách

**Primární tabulka**

- Údaje o cenách potravin jsou dostupné pouze v období **2006–2018**.

**Sekundární tabulka**

- Sekundární tabulka pokrývá 45 evropských států v období 2006–2018 (13 let).
- Počet řádků je 585 (45×13) ⇒ data jsou kompletní pro každý stát a rok v daném období.
- gdp_yoy_pct je NULL v prvním roce každé země (nelze spočítat bez předchozího roku)

## Výzkumné otázky – slovní odpovědi

### Otázka 1  
**Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**  

Z výstupu dotazu vidíme, že většina odvětví vykazuje v čase kladný meziroční růst mezd. Mzdy tedy dlouhodobě rostou. V několika málo letech se však objevují odvětví s mírným poklesem mezd (např. Vzdělávání/2010,2021 nebo Těžba a dobývání/2009,2013,2014,2016 ), což souvisí pravděpodobně s ekonomickými zpomaleními v těchto obdobích. Celkově lze říci, že trend mezd je rostoucí, ale rozhodně ne striktně monotonní. Některá odvětví v jednotlivých letech krátkodobě klesají.

### Otázka 2  
**Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?**  

Z tabulky `t_tomas_havelec_project_sql_primary_final` pro celkový průměr `ALL` vyplývá, že na začátku sledovaného období 2006 bylo možné za průměrnou mzdu koupit přibližně 1,432 litrů mléka a 1,282 kg chleba. Na konci období 2018 tato kupní síla vzrostla na zhruba 1,639 litrů mléka a 1,340 kg chleba. Kupní síla domácností u základních potravin se tedy v čase zvýšila, i když růst není u obou komodit nutně stejně rychlý.

### Otázka 3  
**Která kategorie potravin zdražuje nejpomaleji?**  

Analýza ročních průměrných cen podle kategorií ukazuje, že nejpomaleji zdražující kategorií je krystalový cukr, který má nejnižší průměrný meziroční růst cen v procentech. To znamená, že její cena rostla v čase stabilněji a méně dynamicky než u ostatních potravin. Ostatní kategorie vykazují výrazně vyšší průměrné tempo zdražování.

### Otázka 4  
**Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (o více než 10 p. b.)?**  

Výsledek dotazu srovnávající meziroční růst průměrné mzdy a růst průměrných cen potravin ukazuje, že takové roky neexistují

### Otázka 5  
**Má výška HDP vliv na změny ve mzdách a cenách potravin?**  

Po provedené analýzy nevyplývá jednoznačný přímý vztah mezi výší ani meziročním růstem HDP a okamžitými změnami mezd či cen potravin. U mezd lze pozorovat pouze slabou vazbu, která se může projevit se zpožděním, zatímco u cen potravin se vliv HDP nepotvrdil.


## Jak skripty používat

1. Spusť `primarni_tabulka.sql` – vytvoří tabulku `t_tomas_havelec_project_sql_primary_final`.  
2. Spusť `sekundarni_tabulka.sql` – vytvoří tabulku `t_tomas_havelec_project_sql_secondary_final`.  
3. Spusť jednotlivé dotazy `otazka_1_*.sql` až `otazka_5_*.sql` 

