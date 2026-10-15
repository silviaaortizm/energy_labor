*=============================================================
**# Directorio base
*=============================================================
global path "C:\Users\Silvia\OneDrive\Job\BID\Projects\Energia - Paneles Solares"
global base "$path\databases\Censo 2018 COL"

set more off

* Lista de departamentos
local deptos ///
    05_Antioquia 08_Atlantico 11_Bogota 13_Bolivar 15_Boyaca 17_Caldas 18_Caqueta 19_Cauca 20_Cesar 23_Cordoba 25_Cundinamarca 27_Choco 41_Huila 44_LaGuajira 47_Magdalena 50_Meta 52_Narino 54_NorteDeSantander 63_Quindio 66_Risaralda 68_Santander 70_Sucre 73_Tolima 76_ValleDelCauca 81_Arauca 85_Casanare 86_Putumayo 88_SAI 91_Amazonas 94_Guainia 95_Guaviare 97_Vaupes 99_Vichada

* Temporal donde se acumularán todos los departamentos
tempfile master
local first = 1

*=============================================================
**# Loop por departamento
*=============================================================
foreach depto of local deptos {

    * Código del departamento = primeros dos caracteres
    local depto_num = substr("`depto'", 1, 2)

    di as text "Procesando departamento: `depto' (`depto_num')"
    *-------------------------------------------------------------
* Personas    *-------------------------------------------------------------
import delimited ///
        "${base}\\`depto'\CNPV2018_5PER_A2_`depto_num'.csv",  varnames(1) clear colrange(5:8)

    rename p_nrohog h_nrohog

    keep cod_encuestas u_vivienda h_nrohog p_nro_per

tempfile personas
save `personas', replace
    *-------------------------------------------------------------
* Hogares
*-------------------------------------------------------------
import delimited ///
        "${base}\\`depto'\CNPV2018_2HOG_A2_`depto_num'.csv", varnames(1) clear colrange(5:7)

    keep cod_encuestas u_vivienda h_nrohog
    isid cod_encuestas u_vivienda h_nrohog, missok

tempfile hogares
save `hogares', replace

    *-------------------------------------------------------------
* Vivienda
*-------------------------------------------------------------
import delimited ///
        "${base}\\`depto'\CNPV2018_1VIV_A2_`depto_num'.csv",varnames(1) clear colrange(2:20)

    keep u_dpto u_mpio cod_encuestas u_vivienda va1_estrato va_ee
    isid cod_encuestas u_vivienda, missok
    * Diccionario DANE: 1=Si, 2=No. Mantener missing; no imputar.
    * https://microdatos.dane.gov.co/index.php/catalog/643/variable/F8/V531?name=VA_EE
    tab va_ee, missing
    assert inlist(va_ee, 1, 2) | missing(va_ee)

* Merge vivienda + hogares
    merge 1:m cod_encuestas u_vivienda using `hogares', keep(match) nogen
    isid cod_encuestas u_vivienda h_nrohog, missok

* Merge + personas
	merge 1:m cod_encuestas u_vivienda h_nrohog ///
        using `personas', keep(match) nogen
    
* Collapse a municipio x estrato x servicio de energía eléctrica
    gen n = 1

    collapse (sum) n, by(u_dpto u_mpio va1_estrato va_ee)
    format va1_estrato %20.0f
	
* Acumular departamentos 
    if `first' == 1 {
        save `master', replace
        local first = 0
    }
    else {
        append using `master'
        save `master', replace
    }
}


*=============================================================
**# Base final
*=============================================================
import excel using "${base}\DIVIPOLA_municipios.xlsx", firstrow clear
rename (CodigoDane Descripcion) (cod_mpio municipio)

* Normalizar códigos sin perder ceros iniciales.
capture confirm numeric variable cod_mpio
if _rc == 0 {
    tostring cod_mpio, replace format(%05.0f)
}
replace cod_mpio = strtrim(cod_mpio)
replace cod_mpio = substr("00000" + cod_mpio, -5, 5) if strlen(cod_mpio) < 5
assert strlen(cod_mpio) == 5 & !missing(real(cod_mpio))
isid cod_mpio
local n_divipola = _N

tempfile municipios
save `municipios', replace

use `master', clear

format u_dpto %02.0f
format u_mpio %03.0f

gen str5 cod_mpio = string(u_dpto, "%02.0f") + string(u_mpio, "%03.0f")

drop u_dpto u_mpio
rename (n va1_estrato) (personas estrato)
isid cod_mpio estrato va_ee, missok

* Validar totales contra la salida anterior antes de completar cobertura.
preserve
collapse (sum) personas, by(cod_mpio estrato)
rename personas personas_nuevas
merge 1:1 cod_mpio estrato using ///
    "${base}\censo_personas_municipio_estrato.dta", keepusing(personas)
assert _merge == 3
assert personas_nuevas == personas
di as result "Validación aprobada: mismos conteos por municipio y estrato."
restore

tempfile conteos
save `conteos', replace
use `municipios', clear
* DIVIPOLA es el universo: conservar incluso municipios sin observaciones.
merge 1:m cod_mpio using `conteos'
count if _merge == 2
if r(N) > 0 {
    list cod_mpio estrato va_ee personas if _merge == 2, noobs
    di as error "Hay códigos censales fuera de DIVIPOLA; revisar el catálogo."
    error 459
}
gen byte sin_info_censo = (_merge == 1)
assert missing(estrato) & missing(va_ee) & missing(personas) if sin_info_censo
drop _merge

* Derivar geografía también para municipios sin datos censales.
capture drop dpto mpio
gen str2 dpto = substr(cod_mpio, 1, 2)
gen str3 mpio = substr(cod_mpio, 3, 3)
order cod_mpio municipio dpto mpio estrato va_ee personas sin_info_censo
sort cod_mpio estrato va_ee
isid cod_mpio estrato va_ee, missok
egen byte tag_mpio = tag(cod_mpio)
count if tag_mpio
assert r(N) == `n_divipola'
drop tag_mpio

label define censo_energia 1 "Si" 2 "No", replace
label values va_ee censo_energia
label var va_ee "Vivienda cuenta con servicio de energía eléctrica"
label var personas "Personas vinculadas a vivienda y hogar"
label var sin_info_censo "Municipio DIVIPOLA sin personas vinculadas"
tab va_ee, missing
count if sin_info_censo
di as result "Municipios sin información censal: " r(N)
list cod_mpio municipio if sin_info_censo, noobs

save "${base}\censo_personas_municipio_estrato_va_ee.dta", replace
