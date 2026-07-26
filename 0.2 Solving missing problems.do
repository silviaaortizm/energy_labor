/*==================================================
project:          Solving missings issue
Author:           Silvia Ortiz-Merchan
E-mail:
URL:
Dependencies:
----------------------------------------------------
Creation Date:    13 Jul 2026 - 14:38:34
Modification Date:
Do-file version:  01
References:
Output:
==================================================*/

clear all
set more off
global path "C:\Users\Silvia\OneDrive\Job\BID\Projects\Energia - Paneles Solares"

/*==================================================
Tratamiento a nivel municipio
==================================================*/
use "$path\results\municipiostratados.dta", clear
keep CodigoDane ever_treated
isid CodigoDane
tempfile treatment
save `treatment', replace

*=============================================================
**# 1. BASE DE DATOS YEAR*MES*MUNICIPIO
*=============================================================

*==================================================
**# Corrección missings agosto 2016-mayo 2019 
*   usando shares de agosto 2015 - julio 2016
*==================================================
use "$path/results/Cotizantes_2012-2025_mensual_salud.dta", clear

* Identificar municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"


* Calcular shares municipales usando agosto 2015 - julio 2016
preserve
    keep if (Year==2015 & inrange(Mes,8,12)) | ///
            (Year==2016 & inrange(Mes,1,7))

    * Total de cotizantes del departamento
    * Incluye municipios identificados y sin información
    bysort dpto Mes: egen total_dpto_mes = total(Cotizantes)

    * Share de cada municipio, incluyendo la categoría sin información
    gen share_muni_base = Cotizantes / total_dpto_mes
	
    * Quedarnos solo con variables necesarias
    keep dpto Mes Municipio share_muni_base

	drop if dpto==.
    tempfile shares_base
    save `shares_base'
restore


* Llevar shares del periodo base al resto de años
merge m:1 dpto Mes Municipio using `shares_base', ///
    nogen keep(master match)
drop if dpto==.


* Periodo a corregir:
* agosto 2016 - mayo 2019
gen periodo_ajuste = ///
    (Year==2016 & inrange(Mes,8,12)) | ///
    inlist(Year,2017,2018) | ///
    (Year==2019 & inrange(Mes,1,5))


*==================================================
* Calcular cuánto missing debería mantenerse
*==================================================
/* No se redistribuyen todos los missing: se conserva el nivel histórico observado
  en el periodo base. Por ejemplo, si históricamente 0.1% de los cotizantes del
  departamento no tenía municipio, se mantiene ese 0.1% y solo se redistribuye
  entre los municipios el missing que exceda dicho nivel.*/
  
* Total actual de cotizantes del departamento (de cada año a corregir)
bysort dpto Year Mes: egen total_dpto_actual = ///
    total(cond(periodo_ajuste==1, Cotizantes, 0))

* Total actual sin información
bysort dpto Year Mes: egen cot_no_info = ///
    total(cond(no_info_municipio==1 & periodo_ajuste==1, Cotizantes, 0))

* Missing que debería mantenerse según el share histórico
gen x = total_dpto_actual * share_muni_base ///
    if no_info_municipio==1 & periodo_ajuste==1

* No aumentar los missing si actualmente son menores al nivel histórico
egen cot_missing = rowmin(Cotizantes x) ///
    if no_info_municipio==1 & periodo_ajuste==1

* Total de missing que se mantendrá
bysort dpto Year Mes: egen cot_missing_total = ///
    total(cond(no_info_municipio==1 & periodo_ajuste==1, cot_missing, 0))

* Exceso de missing que se debe redistribuir
gen cot_no_info_exceso = cot_no_info - cot_missing_total ///
    if periodo_ajuste==1 & cot_missing_total!=.


*==================================================
* Redistribuir únicamente el exceso de missing
*==================================================

* Suma de shares históricos de municipios identificados
bysort dpto Year Mes: egen sum_share_muni = ///
    total(cond(no_info_municipio==0 & periodo_ajuste==1, ///
    share_muni_base, 0))

* Redistribuir todo el exceso entre municipios identificados
gen cot_redistribuir = ///
    (share_muni_base / sum_share_muni) * cot_no_info_exceso ///
    if periodo_ajuste==1 & no_info_municipio==0


*==================================================
* Crear cotizantes ajustados
*==================================================

gen Cotizantes_adj = Cotizantes

* Municipios identificados:
* mantener lo observado y sumar su parte del exceso de missing
egen adj_0 = rowtotal(Cotizantes cot_redistribuir) ///
    if periodo_ajuste==1 & no_info_municipio==0

replace Cotizantes_adj = adj_0 ///
    if periodo_ajuste==1 & no_info_municipio==0

* Mantener únicamente el nivel histórico de missing
replace Cotizantes_adj = cot_missing ///
    if no_info_municipio==1 & periodo_ajuste==1


keep Year dpto Municipio Mes Cotizantes_adj
rename Cotizantes_adj Cotizantes

save "$path/results/Cotizantes_2012-2025_mensual_salud_correctedshares.dta", replace


*==================================================
**# Correccion imputando municipios de aportante
*==================================================

use "$path/results/Cotizantes_2012-2025_mensual_salud.dta", clear
	gen no_info_municipio = substr(Municipio,3,3)=="999"
	replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"

preserve
	keep if no_info_municipio==1
	drop no_info_municipio

	tempfile Base1
	save `Base1', replace
restore

preserve
	keep if no_info_municipio==0
	drop no_info_municipio

	tempfile Base2
	save `Base2', replace
restore


import excel "$path\databases\Cotizantes_NoInfo_2012-2025_mensual_salud.xlsx", firstrow clear
drop if Municipio=="99999 - Sin Informacion Amazonas, Guanía, Guaviare, Vaupés Y Vichada"

gen mes_num = .
replace mes_num = 1  if lower(Mes) == "enero"
replace mes_num = 2  if lower(Mes) == "febrero"
replace mes_num = 3  if lower(Mes) == "marzo"
replace mes_num = 4  if lower(Mes) == "abril"
replace mes_num = 5  if lower(Mes) == "mayo"
replace mes_num = 6  if lower(Mes) == "junio"
replace mes_num = 7  if lower(Mes) == "julio"
replace mes_num = 8  if lower(Mes) == "agosto"
replace mes_num = 9  if lower(Mes) == "septiembre"
replace mes_num = 10 if lower(Mes) == "octubre"
replace mes_num = 11 if lower(Mes) == "noviembre"
replace mes_num = 12 if lower(Mes) == "diciembre"

labmask mes_num, val(Mes)
drop Mes
rename mes_num Mes

rename NúmerodeCotizantes Cotizantes2
merge m:1 Year Mes Municipio using `Base1', keep(1 3)

replace Municipioaportante="NR - NO REPORTADO" if Municipioaportante=="3 - No Reportado"
collapse (sum) Cotizantes2 , by(Year Mes Municipioaportante)
gen orig=0

	tempfile BaseNoInfo
	save `BaseNoInfo', replace


use `Base2', clear
	gen orig=1
append using `BaseNoInfo'

replace Cotizantes=Cotizantes2 if orig==0

replace Municipio=Municipioaportante if orig==0

gen dpto2=substr(Municipio,1,2) if orig==0
	replace dpto2="" if dpto2=="NR" 
	destring dpto2, replace
	
	replace dpto = dpto2 if orig==0
	drop Municipioaportante dpto2 Cotizantes2
	
collapse (sum) Cotizantes, by(Year dpto Mes Municipio)	

save "$path/results/Cotizantes_2012-2025_mensual_salud_correctedmuni.dta", replace


*=============================================================
**# 2. BASE DE DATOS YEAR*MES*MUNICIPIO*ACT_ECON
*=============================================================

*==================================================
**# Corrección missings agosto 2016-mayo 2019 
*   usando shares de agosto 2015 - julio 2016
*==================================================
use "$path/results/Cotizantes_2012-2025_mensual_actecon_salud.dta", clear

drop if Year==. & dpto==. & Municipio=="" & Mes==. & ActEconomica==. & Cotizantes==.

* Identificar municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"


* Calcular shares municipales usando agosto 2015 - julio 2016
preserve
    keep if (Year==2015 & inrange(Mes,8,12)) | ///
            (Year==2016 & inrange(Mes,1,7))

    * Total de cotizantes del departamento
    * Incluye municipios identificados y sin información
    bysort dpto Mes ActEconomica: egen total_dpto_mes = total(Cotizantes)

    * Share de cada municipio, incluyendo la categoría sin información
    gen share_muni_base = Cotizantes / total_dpto_mes
	
    * Quedarnos solo con variables necesarias
    keep dpto Mes ActEconomica Municipio share_muni_base

	drop if dpto==.
    tempfile shares_base
    save `shares_base'
restore


* Llevar shares del periodo base al resto de años
merge m:1 dpto Mes ActEconomica Municipio using `shares_base', ///
    nogen keep(master match)
drop if dpto==.


* Periodo a corregir:
* agosto 2016 - mayo 2019
gen periodo_ajuste = ///
    (Year==2016 & inrange(Mes,8,12)) | ///
    inlist(Year,2017,2018) | ///
    (Year==2019 & inrange(Mes,1,5))


*==================================================
* Calcular cuánto missing debería mantenerse
*==================================================
/* No se redistribuyen todos los missing: se conserva el nivel histórico observado
  en el periodo base. Por ejemplo, si históricamente 0.1% de los cotizantes del
  departamento no tenía municipio, se mantiene ese 0.1% y solo se redistribuye
  entre los municipios el missing que exceda dicho nivel.*/
  
* Total actual de cotizantes del departamento (de cada año a corregir)
bysort dpto Year Mes ActEconomica: egen total_dpto_actual = ///
    total(cond(periodo_ajuste==1, Cotizantes, 0))

* Total actual sin información
bysort dpto Year Mes ActEconomica: egen cot_no_info = ///
    total(cond(no_info_municipio==1 & periodo_ajuste==1, Cotizantes, 0))

* Missing que debería mantenerse según el share histórico
gen x = total_dpto_actual * share_muni_base ///
    if no_info_municipio==1 & periodo_ajuste==1

* No aumentar los missing si actualmente son menores al nivel histórico
egen cot_missing = rowmin(Cotizantes x) ///
    if no_info_municipio==1 & periodo_ajuste==1

* Total de missing que se mantendrá
bysort dpto Year Mes ActEconomica: egen cot_missing_total = ///
    total(cond(no_info_municipio==1 & periodo_ajuste==1, cot_missing, 0))

* Exceso de missing que se debe redistribuir
gen cot_no_info_exceso = cot_no_info - cot_missing_total ///
    if periodo_ajuste==1 & cot_missing_total!=.


*==================================================
* Redistribuir únicamente el exceso de missing
*==================================================

* Suma de shares históricos de municipios identificados
bysort dpto Year Mes ActEconomica: egen sum_share_muni = ///
    total(cond(no_info_municipio==0 & periodo_ajuste==1, ///
    share_muni_base, 0))

* Redistribuir todo el exceso entre municipios identificados
gen cot_redistribuir = ///
    (share_muni_base / sum_share_muni) * cot_no_info_exceso ///
    if periodo_ajuste==1 & no_info_municipio==0


*==================================================
* Crear cotizantes ajustados
*==================================================

gen Cotizantes_adj = Cotizantes

* Municipios identificados:
* mantener lo observado y sumar su parte del exceso de missing
egen adj_0 = rowtotal(Cotizantes cot_redistribuir) ///
    if periodo_ajuste==1 & no_info_municipio==0

replace Cotizantes_adj = adj_0 ///
    if periodo_ajuste==1 & no_info_municipio==0

* Mantener únicamente el nivel histórico de missing
replace Cotizantes_adj = cot_missing ///
    if no_info_municipio==1 & periodo_ajuste==1


keep Year dpto Municipio ActEconomica Mes Cotizantes_adj
rename Cotizantes_adj Cotizantes

save "$path/results/Cotizantes_2012-2025_mensual_actecon_salud_correctedshares.dta", replace