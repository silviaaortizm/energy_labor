/*==================================================
project:       Comparison databases (dissag by ActEconomica vs
			   not dissag)
Author:        Silvia Ortiz-Merchan 
E-email:       
url:           
Dependencies:  
----------------------------------------------------
Creation Date:    16 Jul 2026 - 14:10:00
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/
global path "C:\Users\Silvia\OneDrive\Job\BID\Projects\Energia - Paneles Solares"

/*==================================================
 1: Base dissag by ActEconomica 
==================================================*/
use "$path\results\Cotizantes_2012-2025_mensual_actecon_salud.dta", clear

collapse (sum) Cotizantes, by(Municipio Year Mes dpto) //total cotizantes anual por municipio, mes y año
collapse (mean) Cotizantes, by(Municipio Year dpto) //promedio cotizantes mensual = dato anual

collapse (sum) Cotizantes, by(dpto Year) //empleo total anual por departamento

rename Cotizantes Cotizantes_dissag

tempfile cot_anual_dpto
save `cot_anual_dpto', replace


/*==================================================
 2: Base no dissag
==================================================*/
use "$path\results\Cotizantes_2012-2025_mensual_salud.dta", clear


collapse (mean) Cotizantes, by(Municipio Year dpto) //promedio cotizantes mensual = dato anual

collapse (sum) Cotizantes, by(dpto Year) //empleo total anual por departamento

rename Cotizantes Cotizantes_nodissag

merge 1:1 dpto Year using `cot_anual_dpto'

gen share_diff = (Cotizantes_dissag-Cotizantes_nodissag)/Cotizantes_nodissag*100

sum share_diff
assert Cotizantes_dissag >= Cotizantes_nodissag if Cotizantes_dissag !=. & Cotizantes_nodissag !=.
 //al tener la base desagregada dan en promedio 0.4% más de empleados formales en los municipios (oscila entre 0-2.2%)