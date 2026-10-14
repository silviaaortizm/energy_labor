*=============================================================
**# Directorio base
*=============================================================
global path "C:\Users\Silvia\OneDrive\Job\BID\Projects\Energia - Paneles Solares"
global base "$path\databases\Censo 2018 COL"

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

tempfile hogares
save `hogares', replace

    *-------------------------------------------------------------
* Vivienda
*-------------------------------------------------------------
import delimited ///
        "${base}\\`depto'\CNPV2018_1VIV_A2_`depto_num'.csv",varnames(1) clear colrange(2:20)

    keep u_dpto u_mpio cod_encuestas u_vivienda va1_estrato

* Merge vivienda + hogares
    merge 1:m cod_encuestas u_vivienda using `hogares', gen(merge_h)

    keep if merge_h == 3
    drop merge_h

* Merge + personas
	merge 1:m cod_encuestas u_vivienda h_nrohog ///
        using `personas', gen(merge_p)

    keep if merge_p == 3
    drop merge_p
    
* Collapse a municipio x estrato  
    gen n = 1

    collapse (sum) n, by(u_dpto u_mpio va1_estrato)
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

tempfile municipios
save `municipios', replace

use `master', clear

format u_dpto %02.0f
format u_mpio %03.0f

gen str5 cod_mpio = string(u_dpto, "%02.0f") + string(u_mpio, "%03.0f")

gen str2 dpto = string(u_dpto, "%02.0f")
gen str3 mpio = string(u_mpio, "%03.0f")

merge m:1 cod_mpio using `municipios', keep(1 3)
sort u_dpto u_mpio va1_estrato

drop u_dpto u_mpio
order cod_mpio municipio dpto mpio va1_estrato
rename (n va1_estrato) (personas estrato)

drop _merge


save "${base}\censo_personas_municipio_estrato.dta", replace