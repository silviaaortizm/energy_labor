use "$path/results/Cotizantes_2012-2025_mensual_actecon_salud_correctedshares.dta", clear

* Guardar categorías y labels antes del reshape
levelsof ActEconomica, local(acts)
foreach a of local acts {
    local lab_`a' : label (ActEconomica) `a'
}
* Pasar a formato wide
reshape wide Cotizantes, i(Year dpto Municipio Mes) j(ActEconomica)

* Asignar a cada variable el label de la actividad correspondiente
foreach a of local acts {
    label var Cotizantes`a' "Empleo: `lab_`a''"
}

merge 1:1 Year Mes dpto Municipio using "$path/results/Cotizantes_2012-2025_mensual_salud_correctedshares.dta", assert(3) nogen

order Year Mes dpto Municipio Cotizantes Cotizantes*

label var Mes "Mes"
label var dpto "Departamento"
label var Cotizantes "Empleo total"


egen check = rowtotal(Cotizantes1 Cotizantes2 Cotizantes3 Cotizantes4 Cotizantes5 Cotizantes6 Cotizantes7 Cotizantes8 Cotizantes9 Cotizantes10 Cotizantes11 Cotizantes12 Cotizantes13 Cotizantes14 Cotizantes15 Cotizantes16 Cotizantes17 Cotizantes18 Cotizantes19 Cotizantes20 Cotizantes21 Cotizantes22)

compare check Cotizantes
drop check

save "$path/results/Cotizantes_2012-2025.dta", replace
