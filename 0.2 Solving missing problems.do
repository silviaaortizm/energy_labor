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
drop if dpto==.

* Identificar municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"

* Guardar base original desagregada por actividad económica
tempfile base_act
save `base_act', replace


*--------------------------------------------------
* 1. Redistribuir missings entre municipios (procedimiento similar a la sección 1 de este do file)
*--------------------------------------------------
* Pasar temporalmente a nivel año-mes-departamento-municipio
collapse (sum) Cotizantes, by(dpto Year Mes Municipio no_info_municipio)

* Calcular shares municipales del periodo base:
* agosto 2015 - julio 2016
preserve
    keep if (Year==2015 & inrange(Mes,8,12)) | ///
            (Year==2016 & inrange(Mes,1,7))

    * Total del departamento, incluyendo municipios sin información
    bysort dpto Mes: egen total_dpto_mes = total(Cotizantes)

    * Share de cada municipio dentro del departamento
    gen share_muni_base = Cotizantes / total_dpto_mes

    keep dpto Mes Municipio share_muni_base

    drop if dpto==.
    tempfile shares_base
    save `shares_base'
restore

* Llevar los shares del periodo base a los años a corregir
merge m:1 dpto Mes Municipio using `shares_base', ///
    keep(master match) nogen
drop if dpto==.

* Periodo a corregir: agosto 2016 - mayo 2019
gen periodo_ajuste = ///
    (Year==2016 & inrange(Mes,8,12)) | ///
    inlist(Year,2017,2018) | ///
    (Year==2019 & inrange(Mes,1,5))

replace share_muni_base = 0 if share_muni_base==. & periodo_ajuste==1


*--------------------------------------------------
* 1.1. Calcular cuánto missing debe mantenerse
*--------------------------------------------------
/*
No se redistribuyen todos los missing: se conserva el nivel histórico observado
en el periodo base. Por ejemplo, si históricamente 0.1% de los cotizantes del
departamento no tenía municipio, se mantiene ese 0.1% y solo se redistribuye
entre los municipios el missing que exceda dicho nivel.
*/

* Total actual de cotizantes del departamento
bysort dpto Year Mes: egen total_dpto_actual = ///
    total(cond(periodo_ajuste==1, Cotizantes, 0))

* Total actual de cotizantes sin municipio
bysort dpto Year Mes: egen cot_no_info = ///
    total(cond(no_info_municipio==1 & periodo_ajuste==1, Cotizantes, 0))

* Missing que debería mantenerse según el share histórico
gen x = total_dpto_actual * share_muni_base ///
    if no_info_municipio==1 & periodo_ajuste==1

* No aumentar los missing cuando el valor observado ya es menor al histórico
egen cot_missing = rowmin(Cotizantes x) ///
    if no_info_municipio==1 & periodo_ajuste==1

* Total de missing que se mantendrá en cada departamento-mes
bysort dpto Year Mes: egen cot_missing_total = ///
    total(cond(no_info_municipio==1 & periodo_ajuste==1, cot_missing, 0))

* Exceso de missing que sí debe redistribuirse
gen cot_no_info_exceso = cot_no_info - cot_missing_total ///
    if periodo_ajuste==1 & cot_missing_total!=.


*--------------------------------------------------
* 1.2. Redistribuir el exceso entre municipios
*--------------------------------------------------
* Suma de los shares históricos de municipios identificados
bysort dpto Year Mes: egen sum_share_muni = ///
    total(cond(no_info_municipio==0 & periodo_ajuste==1, ///
    share_muni_base, 0))

* Redistribuir el exceso según los shares municipales históricos
gen cot_redistribuir = ///
    (share_muni_base / sum_share_muni) * cot_no_info_exceso ///
    if periodo_ajuste==1 & no_info_municipio==0

* Extra final asignado a cada municipio:
* redistribución para municipios identificados y missing conservado para no identificados
egen extra_cot = rowtotal(cot_redistribuir cot_missing)


*--------------------------------------------------
* 1.3. Chequear conservación del total departamental
*--------------------------------------------------
preserve
    clonevar Cotizantes2 = Cotizantes

    * Retirar los missing originales en el periodo corregido
    replace Cotizantes2 = 0 if periodo_ajuste==1 & no_info_municipio==1

    * Agregar redistribución municipal y missing que se conserva
    egen Cotizantes_adj = rowtotal(Cotizantes2 extra_cot)

    collapse (sum) Cotizantes Cotizantes_adj, by(Year Mes dpto)

    assert abs(Cotizantes-Cotizantes_adj)<1
    dis "Pasa el chequeo de que se mantiene la misma cantidad de cotizantes por year*mes*dpto"
restore

* Guardar únicamente el extra que debe asignarse a cada municipio
keep Year dpto Municipio Mes no_info_municipio cot_no_info extra_cot

tempfile extras_cot
save `extras_cot', replace


*--------------------------------------------------
* 2. Redistribuir los extras entre actividades económicas
*--------------------------------------------------
* Volver a la base original desagregada por actividad
use `base_act', clear

* Llevar a cada actividad el extra total asignado a su municipio
merge m:1 Year Mes dpto Municipio using `extras_cot', ///
    keepusing(extra_cot) nogen

* Periodo a corregir: agosto 2016 - mayo 2019
gen periodo_ajuste = ///
    (Year==2016 & inrange(Mes,8,12)) | ///
    inlist(Year,2017,2018) | ///
    (Year==2019 & inrange(Mes,1,5))


*--------------------------------------------------
* 2.1. Calcular shares históricos de actividad por municipio
*-------------------------------------------------
preserve
    keep if (Year==2015 & inrange(Mes,8,12)) | ///
            (Year==2016 & inrange(Mes,1,7))

    * Total de cotizantes del municipio en cada mes del periodo base
    bysort dpto Year Mes Municipio: egen total_muni_act_mes = total(Cotizantes)

    * Share de cada actividad dentro del municipio
    gen share_act_muni = Cotizantes / total_muni_act_mes

    keep dpto Mes Municipio ActEconomica share_act_muni

    drop if dpto==.
    tempfile shares_muni
    save `shares_muni'
restore


*--------------------------------------------------
* 2.2. Calcular shares históricos de actividad por departamento
*--------------------------------------------------
/*
Los shares departamentales se utilizan como alternativa cuando no existe
información histórica suficiente para construir el share de actividad
a nivel municipal.
*/

preserve
    keep if (Year==2015 & inrange(Mes,8,12)) | ///
            (Year==2016 & inrange(Mes,1,7))

    * Agregar cotizantes por departamento y actividad
    collapse (sum) Cotizantes, by(dpto Year Mes ActEconomica)

    * Total de cotizantes del departamento
    bysort dpto Year Mes: egen total_dpto_act_mes = total(Cotizantes)

    * Share de cada actividad dentro del departamento
    gen share_act_dpto = Cotizantes / total_dpto_act_mes

    keep dpto Mes ActEconomica share_act_dpto

    drop if dpto==.
    tempfile shares_dpto
    save `shares_dpto'
restore


*--------------------------------------------------
* 2.3. Llevar shares históricos a la base
*--------------------------------------------------
* Share de actividad a nivel municipal
merge m:1 dpto Mes Municipio ActEconomica using `shares_muni', ///
    keep(master match) gen(merge_share_muni)

* Share de actividad a nivel departamental
merge m:1 dpto Mes ActEconomica using `shares_dpto', ///
    keep(master match) gen(merge_share_dpto)

drop if dpto==.


*--------------------------------------------------
* 2.4. Estandarizar shares entre las actividades
*      existentes en cada periodo
*--------------------------------------------------
/*
Los shares se renormalizan utilizando únicamente las actividades presentes
en cada año-mes-municipio. Así, si una actividad existía en el periodo base
pero no aparece en el periodo a corregir, el 100% del extra se distribuye
entre las actividades que sí están presentes.
*/

* Estandarizar shares municipales
bysort Year Mes dpto Municipio: egen share_total = total(share_act_muni)
gen share_act_muni_std = share_act_muni/share_total

* Comprobar suma de shares municipales estandarizados
bysort Year Mes dpto Municipio: egen share_total2 = total(share_act_muni_std)

drop share_act_muni share_total
rename (share_act_muni_std share_total2) ///
       (share_act_muni share_act_muni_total)

* Estandarizar shares departamentales según las actividades presentes
* Renormalizar los shares departamentales entre las actividades
* que efectivamente existen en cada municipio
bysort Year Mes dpto Municipio: egen share_dpto_muni_total = ///
    total(share_act_dpto)

gen share_act_dpto_muni = ///
    share_act_dpto / share_dpto_muni_total ///
    if share_dpto_muni_total>0


*--------------------------------------------------
* 2.5. Redistribuir los extras entre actividades
*--------------------------------------------------
* Usar shares municipales cuando existe información histórica del municipio
gen cot_redistribuir = ///
    share_act_muni * extra_cot ///
    if periodo_ajuste==1 & share_act_muni_total>0.99

* Si no existen shares municipales, usar los shares departamentales
replace cot_redistribuir = ///
    share_act_dpto_muni * extra_cot ///
    if periodo_ajuste==1 & share_act_muni_total==0


*--------------------------------------------------
* 2.6. Chequear conservación de los extras por municipio
*--------------------------------------------------
preserve
    * Sumar el extra repartido entre actividades
    bysort Year Mes dpto Municipio: egen extra_cot_act = ///
        total(cot_redistribuir)

    * Una observación por municipio para realizar la comparación
    egen tag_muni = tag(Year Mes dpto Municipio)

    * El extra municipal debe ser igual a la suma del extra por actividades
    compare extra_cot extra_cot_act ///
        if tag_muni==1 & periodo_ajuste==1

    dis "Pasa el chequeo de que se mantiene la misma cantidad de cotizantes por year*mes*municipio"

    * Construir temporalmente los cotizantes ajustados
    clonevar Cotizantes2 = Cotizantes
    replace Cotizantes2 = 0 if periodo_ajuste==1 & no_info_municipio==1

    egen Cotizantes_adj = rowtotal(Cotizantes2 cot_redistribuir)

    * Comprobar conservación del total a nivel departamento
    collapse (sum) Cotizantes Cotizantes_adj, by(Year Mes dpto)

    assert abs(Cotizantes-Cotizantes_adj)<1
    dis "Pasa el chequeo de que se mantiene la misma cantidad de cotizantes por year*mes*dpto"
restore


*--------------------------------------------------
* 2.7. Construir base final corregida
*--------------------------------------------------
* Retirar los missing originales durante el periodo corregido
replace Cotizantes = 0 if periodo_ajuste==1 & no_info_municipio==1

* Mantener cotizantes originales y sumar los redistribuidos por actividad
egen Cotizantes_adj = rowtotal(Cotizantes cot_redistribuir)


*--------------------------------------------------
* 2.8. Guardar base corregida
*--------------------------------------------------
keep Year dpto Municipio Mes ActEconomica Cotizantes_adj
rename Cotizantes_adj Cotizantes

save "$path/results/Cotizantes_2012-2025_mensual_actecon_salud_correctedshares.dta", replace

/*==================================================
**# Corrección missings agosto 2016-mayo 2019 
*   usando shares de agosto 2015 - julio 2016
* en este caso se calcula un share desde e inicio para mes*dpto*municipio*años
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

save "$path/results/Cotizantes_2012-2025_mensual_actecon_salud_correctedshares_v2.dta", replace*/