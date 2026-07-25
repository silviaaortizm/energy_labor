/*==================================================
project:       Joining all the years of Cotizantes by
				municipio*year*month*econ_activity
Author:        Silvia Ortiz-Merchan 
E-email:       
url:           
Dependencies:  
----------------------------------------------------
Creation Date:    16 Jul 2026 - 10:02:07
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/
global path "C:\Users\Silvia\OneDrive\Job\BID\Projects\Energia - Paneles Solares"

/*==================================================
1: Base desagregada por actividad económica. 
	Año*Municipio*Act_Economica*Mes
==================================================*/
import excel  "$path/databases/Cotizantes_2012-2025_mensual_actecon_salud.xlsx", firstrow sheet("2012-2016") clear
tempfile part1
save `part1', replace

import excel  "$path/databases/Cotizantes_2012-2025_mensual_actecon_salud.xlsx", firstrow sheet("2017-2020") clear
tempfile part2
save `part2', replace

import excel  "$path/databases/Cotizantes_2012-2025_mensual_actecon_salud.xlsx", firstrow sheet("2021-2024") clear
tempfile part3
save `part3', replace


import excel  "$path/databases/Cotizantes_2012-2025_mensual_actecon_salud.xlsx", firstrow sheet("2025") clear
tempfile part4
save `part4', replace

use `part1', clear
append using `part2'
append using `part3'
append using `part4'

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


gen dpto=substr(Municipio,1,2)
replace dpto="" if dpto=="NR" 

gen dpto_name = ""
replace dpto_name = "Antioquia"	if dpto == "05"
replace dpto_name = "Atlántico"	if dpto == "08"
replace dpto_name = "Bogotá, D.C."	if dpto == "11"
replace dpto_name = "Bolívar"	if dpto == "13"
replace dpto_name = "Boyacá"	if dpto == "15"
replace dpto_name = "Caldas"	if dpto == "17"
replace dpto_name = "Caquetá"	if dpto == "18"
replace dpto_name = "Cauca"	if dpto == "19"
replace dpto_name = "Cesar"	if dpto == "20"
replace dpto_name = "Córdoba"	if dpto == "23"
replace dpto_name = "Cundinamarca"	if dpto == "25"
replace dpto_name = "Chocó"	if dpto == "27"
replace dpto_name = "Huila"	if dpto == "41"
replace dpto_name = "La Guajira"	if dpto == "44"
replace dpto_name = "Magdalena"	if dpto == "47"
replace dpto_name = "Meta"	if dpto == "50"
replace dpto_name = "Nariño"	if dpto == "52"
replace dpto_name = "Norte De Santander"	if dpto == "54"
replace dpto_name = "Quindío"	if dpto == "63"
replace dpto_name = "Risaralda"	if dpto == "66"
replace dpto_name = "Santander"	if dpto == "68"
replace dpto_name = "Sucre"	if dpto == "70"
replace dpto_name = "Tolima"	if dpto == "73"
replace dpto_name = "Valle Del Cauca"	if dpto == "76"
replace dpto_name = "Arauca"	if dpto == "81"
replace dpto_name = "Casanare"	if dpto == "85"
replace dpto_name = "Putumayo"	if dpto == "86"
replace dpto_name = "Archipiélago De San Andrés, Providencia Y Santa Catalina"	if dpto == "88"
replace dpto_name = "Amazonas"	if dpto == "91"
replace dpto_name = "Guainía"	if dpto == "94"
replace dpto_name = "Guaviare"	if dpto == "95"
replace dpto_name = "Vaupés"	if dpto == "97"
replace dpto_name = "Vichada"	if dpto == "99"
replace dpto_name = "No info"	if dpto == ""

destring dpto, replace
labmask dpto, val(dpto_name)
drop dpto_name

encode ActividadEcon, gen(ActEconomica)
drop ActividadEcon

rename Año Year
rename NúmerodeCotizantes Cotizantes

order Year dpto Municipio Mes ActEconomica Cotizantes 

save "$path/results/Cotizantes_2012-2025_mensual_actecon_salud.dta", replace

/*==================================================
2: Base por Año*Municipio*Mes
==================================================*/
import excel "$path\databases\Cotizantes_2012-2025_mensual_salud.xlsx", firstrow clear

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

rename Año Year
rename NúmerodeCotizantes Cotizantes


gen dpto=substr(Municipio,1,2)
replace dpto="" if dpto=="NR" 

gen dpto_name = ""
replace dpto_name = "Antioquia"	if dpto == "05"
replace dpto_name = "Atlántico"	if dpto == "08"
replace dpto_name = "Bogotá, D.C."	if dpto == "11"
replace dpto_name = "Bolívar"	if dpto == "13"
replace dpto_name = "Boyacá"	if dpto == "15"
replace dpto_name = "Caldas"	if dpto == "17"
replace dpto_name = "Caquetá"	if dpto == "18"
replace dpto_name = "Cauca"	if dpto == "19"
replace dpto_name = "Cesar"	if dpto == "20"
replace dpto_name = "Córdoba"	if dpto == "23"
replace dpto_name = "Cundinamarca"	if dpto == "25"
replace dpto_name = "Chocó"	if dpto == "27"
replace dpto_name = "Huila"	if dpto == "41"
replace dpto_name = "La Guajira"	if dpto == "44"
replace dpto_name = "Magdalena"	if dpto == "47"
replace dpto_name = "Meta"	if dpto == "50"
replace dpto_name = "Nariño"	if dpto == "52"
replace dpto_name = "Norte De Santander"	if dpto == "54"
replace dpto_name = "Quindío"	if dpto == "63"
replace dpto_name = "Risaralda"	if dpto == "66"
replace dpto_name = "Santander"	if dpto == "68"
replace dpto_name = "Sucre"	if dpto == "70"
replace dpto_name = "Tolima"	if dpto == "73"
replace dpto_name = "Valle Del Cauca"	if dpto == "76"
replace dpto_name = "Arauca"	if dpto == "81"
replace dpto_name = "Casanare"	if dpto == "85"
replace dpto_name = "Putumayo"	if dpto == "86"
replace dpto_name = "Archipiélago De San Andrés, Providencia Y Santa Catalina"	if dpto == "88"
replace dpto_name = "Amazonas"	if dpto == "91"
replace dpto_name = "Guainía"	if dpto == "94"
replace dpto_name = "Guaviare"	if dpto == "95"
replace dpto_name = "Vaupés"	if dpto == "97"
replace dpto_name = "Vichada"	if dpto == "99"
replace dpto_name = "No info"	if dpto == ""

destring dpto, replace
labmask dpto, val(dpto_name)
drop dpto_name

replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."

order Year dpto Municipio Mes Cotizantes

save "$path/results/Cotizantes_2012-2025_mensual_salud.dta", replace

/*==================================================
3: Base por Año*Municipio*Mes (Municipio del aportante)
==================================================*/
import excel "$path\databases\Cotizantes_2012-2025_mensual_salud_v2.xlsx", firstrow clear

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

rename NúmerodeCotizantes Cotizantes
rename dpto depto

gen dpto=substr(Municipio,1,2)
replace dpto="" if dpto=="NR" 
replace dpto="" if dpto=="3 " 

gen dpto_name = ""
replace dpto_name = "Antioquia"	if dpto == "05"
replace dpto_name = "Atlántico"	if dpto == "08"
replace dpto_name = "Bogotá, D.C."	if dpto == "11"
replace dpto_name = "Bolívar"	if dpto == "13"
replace dpto_name = "Boyacá"	if dpto == "15"
replace dpto_name = "Caldas"	if dpto == "17"
replace dpto_name = "Caquetá"	if dpto == "18"
replace dpto_name = "Cauca"	if dpto == "19"
replace dpto_name = "Cesar"	if dpto == "20"
replace dpto_name = "Córdoba"	if dpto == "23"
replace dpto_name = "Cundinamarca"	if dpto == "25"
replace dpto_name = "Chocó"	if dpto == "27"
replace dpto_name = "Huila"	if dpto == "41"
replace dpto_name = "La Guajira"	if dpto == "44"
replace dpto_name = "Magdalena"	if dpto == "47"
replace dpto_name = "Meta"	if dpto == "50"
replace dpto_name = "Nariño"	if dpto == "52"
replace dpto_name = "Norte De Santander"	if dpto == "54"
replace dpto_name = "Quindío"	if dpto == "63"
replace dpto_name = "Risaralda"	if dpto == "66"
replace dpto_name = "Santander"	if dpto == "68"
replace dpto_name = "Sucre"	if dpto == "70"
replace dpto_name = "Tolima"	if dpto == "73"
replace dpto_name = "Valle Del Cauca"	if dpto == "76"
replace dpto_name = "Arauca"	if dpto == "81"
replace dpto_name = "Casanare"	if dpto == "85"
replace dpto_name = "Putumayo"	if dpto == "86"
replace dpto_name = "Archipiélago De San Andrés, Providencia Y Santa Catalina"	if dpto == "88"
replace dpto_name = "Amazonas"	if dpto == "91"
replace dpto_name = "Guainía"	if dpto == "94"
replace dpto_name = "Guaviare"	if dpto == "95"
replace dpto_name = "Vaupés"	if dpto == "97"
replace dpto_name = "Vichada"	if dpto == "99"
replace dpto_name = "No info"	if dpto == ""

destring dpto, replace
labmask dpto, val(dpto_name)
drop dpto_name
drop depto

replace Municipio = "11001 - Bogotá, D.C." if Municipio=="11999 - Bogotá, D.C."

order Year dpto Municipio Mes Cotizantes

save "$path/results/Cotizantes_2012-2025_mensual_salud_v2.dta", replace
