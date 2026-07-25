/*==================================================
project:          Trends graph (treated Vs. No treated)
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
1: Tratamiento a nivel municipio
==================================================*/
use "$path\results\municipiostratados.dta", clear
keep CodigoDane ever_treated
isid CodigoDane
tempfile treatment
save `treatment', replace

/*==================================================
2: Usando la base de Cotizantes por: Year*Municipio*Mes
==================================================*/
use "$path\results\Cotizantes_2012-2025_mensual_salud.dta", clear

** Exclusión de ciudades y departamentos
replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."
drop if inlist(Municipio, "05001 - Medellín", "11001 - Bogotá, D.C.", "76001 - Cali")
drop if inlist(dpto, 52, 85, 88, 91, 94, 95, 97, 99)

** Identificación de municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"

** Construcción del código DANE
gen CodigoDane = substr(Municipio,1,5)
gen length = strlen(CodigoDane)

** Incorporación del tratamiento
merge m:1 CodigoDane using `treatment'
drop if _merge==2
drop _merge

** Fecha mensual
gen fecha = ym(Year,Mes)
format fecha %tm
sort fecha Municipio

/*==================================================
2a: Gráficas de tendencias a nivel mensual y anual
==================================================*/
**# Tendencia mensual general
preserve
collapse (sum) Cotizantes, by(ever_treated fecha)
replace ever_treated=2 if missing(ever_treated)
reshape wide Cotizantes, i(fecha) j(ever_treated)
rename (Cotizantes0 Cotizantes1 Cotizantes2) ///
       (Cotizantes_notreated Cotizantes_treated Cotizantes_missing)
	   
label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

twoway ///
    (line Cotizantes_treated fecha) ///
    (line Cotizantes_notreated fecha) ///
    (line Cotizantes_missing fecha), ///
    legend(pos(6) rows(1)) ///
    xtitle("Fecha") ///
    ytitle("Número de cotizantes")
graph export "$path\graphs\Trends_mensual_general.png", replace
restore

**# Tendencia anual general
preserve
collapse (mean) Cotizantes, by(Year Municipio dpto ever_treated)
replace ever_treated=2 if missing(ever_treated)
collapse (sum) Cotizantes, by(Year ever_treated)
reshape wide Cotizantes, i(Year) j(ever_treated)
rename (Cotizantes0 Cotizantes1 Cotizantes2) ///
       (Cotizantes_notreated Cotizantes_treated Cotizantes_missing)
	   
label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

twoway ///
    (connected Cotizantes_treated Year) ///
    (connected Cotizantes_notreated Year) ///
    (connected Cotizantes_missing Year), ///
    legend(pos(6) cols(3) rows(1)) ///
    xtitle("Año") ///
    ytitle("Número promedio mensual de cotizantes")
graph export "$path\graphs\Trends_anual_general.png", replace
restore


/*==================================================
2: Usando la base de Cotizantes por: Year*Municipio*Mes (municipio del aportante)
==================================================*/
use "$path\results\Cotizantes_2012-2025_mensual_salud_v2.dta", clear

** Exclusión de ciudades y departamentos
replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."
drop if inlist(Municipio, "05001 - Medellín", "11001 - Bogotá, D.C.", "76001 - Cali")
drop if inlist(dpto, 52, 85, 88, 91, 94, 95, 97, 99)

** Identificación de municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO" | Municipio=="3 - No Reportado"

** Construcción del código DANE
gen CodigoDane = substr(Municipio,1,5)
gen length = strlen(CodigoDane)

** Incorporación del tratamiento
merge m:1 CodigoDane using `treatment'
drop if _merge==2
drop _merge

** Fecha mensual
gen fecha = ym(Year,Mes)
format fecha %tm
sort fecha Municipio

/*==================================================
2a: Gráficas de tendencias a nivel mensual y anual
==================================================*/
**# Tendencia mensual general
preserve
collapse (sum) Cotizantes, by(ever_treated fecha)
replace ever_treated=2 if missing(ever_treated)
reshape wide Cotizantes, i(fecha) j(ever_treated)
rename (Cotizantes0 Cotizantes1 Cotizantes2) ///
       (Cotizantes_notreated Cotizantes_treated Cotizantes_missing)
	   
label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

twoway ///
    (line Cotizantes_treated fecha) ///
    (line Cotizantes_notreated fecha) ///
    (line Cotizantes_missing fecha), ///
    legend(pos(6) rows(1)) ///
    xtitle("Fecha") ///
    ytitle("Número de cotizantes")
graph export "$path\graphs\Trends_mensual_general_v2.png", replace
restore

**# Tendencia anual general
preserve
collapse (mean) Cotizantes, by(Year Municipio dpto ever_treated)
replace ever_treated=2 if missing(ever_treated)
collapse (sum) Cotizantes, by(Year ever_treated)
reshape wide Cotizantes, i(Year) j(ever_treated)
rename (Cotizantes0 Cotizantes1 Cotizantes2) ///
       (Cotizantes_notreated Cotizantes_treated Cotizantes_missing)
	   
label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

twoway ///
    (connected Cotizantes_treated Year) ///
    (connected Cotizantes_notreated Year) ///
    (connected Cotizantes_missing Year), ///
    legend(pos(6) cols(3) rows(1)) ///
    xtitle("Año") ///
    ytitle("Número promedio mensual de cotizantes")
graph export "$path\graphs\Trends_anual_general_v2.png", replace
restore


/*==================================================
3: Usando la base de Cotizantes por: 
Year*Municipio*Mes*ActEconomica
==================================================*/
use "$path\results\Cotizantes_2012-2025_mensual_actecon_salud.dta", clear

** Limpieza de la base
drop if Year==. & dpto==. & Municipio=="" & Mes==. & ActEconomica==. & Cotizantes==.
replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."
drop if inlist(Municipio, "05001 - Medellín", "11001 - Bogotá, D.C.", "76001 - Cali") // grandes ciudades
drop if inlist(dpto, 52, 85, 88, 91, 94, 95, 97, 99) // departamentos excluidos


** Identificación de municipios sin información
gen no_info_municipio=(substr(Municipio,3,3)=="999")
replace no_info_municipio=1 if Municipio=="" | Municipio=="NR - NO REPORTADO"

** Construcción del código DANE
gen CodigoDane=substr(Municipio,1,5)
gen length=strlen(CodigoDane)
//assert length==5 if no_info_municipio==0

** Etiquetas de actividad económica
label define short_act ///
    1  "A - Agro y pesca" ///
    2  "B - Minas" ///
    3  "C - Manufactura" ///
    4  "D - Electricidad y gas" ///
    5  "E - Agua y saneamiento" ///
    6  "F - Construcción" ///
    7  "G - Comercio y vehículos" ///
    8  "H - Transporte" ///
    9  "I - Alojamiento y comida" ///
    10 "J - Información y com." ///
    11 "K - Finanzas y seguros" ///
    12 "L - Inmobiliarias" ///
    13 "M - Profesionales y CT" ///
    14 "N - Servicios admin." ///
    15 "ND - No definido" ///
    16 "O - Admón. pública" ///
    17 "P - Educación" ///
    18 "Q - Salud y asistencia" ///
    19 "R - Arte y recreación" ///
    20 "S - Otros servicios" ///
    21 "T - Hogares empleadores" ///
    22 "U - Extraterritoriales", replace
label values ActEconomica short_act

** Incorporación del tratamiento
merge m:1 CodigoDane using `treatment'
drop if _merge==2 //municipios de los que tendriamos tratamiento pero no cotizantes
drop _merge

** Construcción de la fecha
gen fecha=ym(Year,Mes)
format fecha %tm
sort Year Municipio Mes ActEconomica

** Agregación por actividad económica y tratamiento
preserve
collapse (sum) Cotizantes, by(fecha ActEconomica ever_treated)
replace ever_treated=2 if missing(ever_treated)
reshape wide Cotizantes, i(fecha ActEconomica) j(ever_treated)

rename Cotizantes0 Cotizantes_notreated
rename Cotizantes1 Cotizantes_treated
rename Cotizantes2 Cotizantes_missing

label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

/*==================================================
3a: Tendencias por actividad económica
==================================================*/

**# Tendencias de tratados Vs. no tratados por actividad económica
local actividades1 "2,4,5,10,11"
local actividades2 "12,19,21,22"
local actividades3 "1,8,9,17,18"
local actividades4 "3,6,14,16,20"
local actividades5 "7,13,15"

forvalues i=1/5 {
    twoway ///
        (line Cotizantes_treated fecha) ///
        (line Cotizantes_notreated fecha) ///
        (line Cotizantes_missing fecha) ///
        if inlist(ActEconomica,`actividades`i''), ///
        by(ActEconomica, ///
            title(, size(vsmall)) ///
            cols(2) ///
            compact ///
            note("") ///
            legend(pos(6))) ///
        xlabel(, angle(90) labsize(small)) ///
        xtitle("Fecha") ///
        ytitle("Número de cotizantes")
    graph export "$path\graphs\Trends_activecon_mensual_part`i'.png", replace
}
restore

/*==================================================
3b: Tendencias de municipios sin información
==================================================*/
** Base temporal con municipios sin información
preserve
keep if no_info_municipio==1
collapse (sum) Cotizantes, by(ActEconomica fecha)
sort ActEconomica fecha

**# Municipios sin información por actividad económica
xtset ActEconomica fecha
xtline Cotizantes, ///
    overlay ///
    i(ActEconomica) ///
    t(fecha) ///
    xtitle("Fecha") ///
    ytitle("Número de cotizantes") ///
    legend(pos(6) cols(3) size(tiny)) ///
    xlabel(, angle(90))

graph export "$path\graphs\Trends_missing_municipio_actecon.png", replace
restore


/*==================================================
4: Tasas de crecimiento de cotizantes, por municipio anual
Usando la base de Cotizantes por: Year*Municipio*Mes
==================================================*/
** Agregación por tratamiento y depto
use "$path\results\Cotizantes_2012-2025_mensual_salud.dta", clear

** Exclusión de ciudades y departamentos
replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."
drop if inlist(Municipio, "05001 - Medellín", "11001 - Bogotá, D.C.", "76001 - Cali")
drop if inlist(dpto, 52, 85, 88, 91, 94, 95, 97, 99)

** Construcción de la fecha
gen fecha=ym(Year,Mes)
format fecha %tm

gen id_municipio= substr(Municipio, 1,5)
	replace id_municipio="999999" if inlist(id_municipio, "NR - ", "")
	replace Municipio="NR - NO REPORTADO" if inlist(Municipio,"")

destring id_municipio, replace
labmask id_municipio, val(Municipio)

collapse (sum) Cotizantes, by(Year Mes fecha dpto Municipio id_municipio)

/*xtset id_municipio fecha
xtline Cotizantes if dpto==5, ///
    overlay ///
    i(id_municipio) ///
    t(fecha) ///
    xtitle("Fecha") ///
    ytitle("Número de cotizantes") ///
    xlabel(, angle(90) labsize(small)) ///
    legend(pos(6) cols(2) size(tiny))*/
	
collapse (mean) Cotizantes, by(Year dpto id_municipio)	

xtset id_municipio Year
sort id_municipio Year

gen tasa_crecim_anual = (Cotizantes - L.Cotizantes) / L.Cotizantes

drop Cotizantes
reshape wide tasa_crecim_anual, i(dpto id_municipio) j(Year)

export excel using "$path\results\Tasascrecim_cotizantes_muni_anual.xlsx", firstrow(variables) replace



**# Usando la base corregida por shares (2016)

/*==================================================
2: Usando la base de Cotizantes por: Year*Municipio*Mes
==================================================*/
use "$path\results\municipiostratados.dta", clear
keep CodigoDane ever_treated
isid CodigoDane
tempfile treatment
save `treatment', replace

use "$path\results\Cotizantes_2012-2025_mensual_salud_correctedshares.dta", clear

** Exclusión de ciudades y departamentos
replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."
drop if inlist(Municipio, "05001 - Medellín", "11001 - Bogotá, D.C.", "76001 - Cali")
drop if inlist(dpto, 52, 85, 88, 91, 94, 95, 97, 99)

** Identificación de municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"

** Construcción del código DANE
gen CodigoDane = substr(Municipio,1,5)
gen length = strlen(CodigoDane)

** Incorporación del tratamiento
merge m:1 CodigoDane using `treatment'
drop if _merge==2
drop _merge

** Fecha mensual
gen fecha = ym(Year,Mes)
format fecha %tm
sort fecha Municipio

drop if dpto==.

/*==================================================
2a: Gráficas de tendencias a nivel mensual y anual
==================================================*/
** Tendencia mensual general
preserve
collapse (sum) Cotizantes, by(ever_treated fecha)
replace ever_treated=2 if missing(ever_treated)
reshape wide Cotizantes, i(fecha) j(ever_treated)
rename (Cotizantes0 Cotizantes1 Cotizantes2) ///
       (Cotizantes_notreated Cotizantes_treated Cotizantes_missing)
	   
label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

twoway ///
    (line Cotizantes_treated fecha) ///
    (line Cotizantes_notreated fecha) ///
    (line Cotizantes_missing fecha), ///
    legend(pos(6) rows(1)) ///
    xtitle("Fecha") ///
    ytitle("Número de cotizantes")
graph export "$path\graphs\Trends_mensual_general_correctedshares.png", replace
restore

**# Usando la base corregida por shares (2015-2016)
/*==================================================
2: Usando la base corregida con shares 2015-2016
==================================================*/
use "$path\results\municipiostratados.dta", clear
keep CodigoDane ever_treated
isid CodigoDane
tempfile treatment
save `treatment', replace

use "$path\results\Cotizantes_2012-2025_mensual_salud_correctedsharesv2.dta", clear

** Exclusión de ciudades y departamentos
replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."
drop if inlist(Municipio, "05001 - Medellín", "11001 - Bogotá, D.C.", "76001 - Cali")
drop if inlist(dpto, 52, 85, 88, 91, 94, 95, 97, 99)

** Identificación de municipios sin información
gen no_info_municipio = substr(Municipio,3,3)=="999"
replace no_info_municipio = 1 if Municipio=="" | Municipio=="NR - NO REPORTADO"

** Construcción del código DANE
gen CodigoDane = substr(Municipio,1,5)
gen length = strlen(CodigoDane)

** Incorporación del tratamiento
merge m:1 CodigoDane using `treatment'
drop if _merge==2
drop _merge

** Fecha mensual
gen fecha = ym(Year,Mes)
format fecha %tm
sort fecha Municipio

drop if dpto==.

/*==================================================
2a: Gráficas de tendencias a nivel mensual y anual
==================================================*/
** Tendencia mensual general
preserve
collapse (sum) Cotizantes, by(ever_treated fecha)
replace ever_treated=2 if missing(ever_treated)
reshape wide Cotizantes, i(fecha) j(ever_treated)
rename (Cotizantes0 Cotizantes1 Cotizantes2) ///
       (Cotizantes_notreated Cotizantes_treated Cotizantes_missing)
	   
label var Cotizantes_treated "Tratados"
label var Cotizantes_notreated "No tratados"
label var Cotizantes_missing "Missing municipio"

twoway ///
    (line Cotizantes_treated fecha) ///
    (line Cotizantes_notreated fecha) ///
    (line Cotizantes_missing fecha), ///
    legend(pos(6) rows(1)) ///
    xtitle("Fecha") ///
    ytitle("Número de cotizantes")
graph export "$path\graphs\Trends_mensual_general_corrected_sharesv2.png", replace
restore
