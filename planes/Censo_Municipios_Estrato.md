# Censo 2018: personas por municipio, estrato y energía eléctrica

Script: `scripts/extra scripts/Censo_Municipios_Estrato.do`.
Plan actualizado: 15 de octubre de 2026.

## Objetivo y procedimiento

Vincular viviendas, hogares y personas por departamento, conservar únicamente
coincidencias completas y contar personas por municipio, estrato y `va_ee`.
Completar el universo municipal con DIVIPOLA y validar los conteos contra la
base anterior. Mantener este plan actualizado con cada modificación del script.

Ejecutar `Censo_Municipios_Estrato.do` en Stata, con los CSV de los 32
departamentos y Bogotá, `DIVIPOLA_municipios.xlsx` y la salida anterior
`censo_personas_municipio_estrato.dta` en `databases/Censo 2018 COL`.
El directorio del proyecto se configura en el global `path` del script.

## Resultado

`censo_personas_municipio_estrato_va_ee.dta` contiene una fila por municipio,
estrato y `va_ee`. `personas` cuenta personas vinculadas a un hogar y una
vivienda; no cuenta viviendas. Se mantienen los criterios originales de
conservar únicamente coincidencias en ambos cruces.

Según el [diccionario del DANE](https://microdatos.dane.gov.co/index.php/catalog/643/variable/F8/V531?name=VA_EE),
`VA_EE` indica si la vivienda cuenta con energía eléctrica: 1 = Sí, 2 = No.
Los valores faltantes se conservan como categoría; un código distinto de
1, 2 o faltante detiene la ejecución para revisión.

Cada municipio de DIVIPOLA sin personas vinculadas aparece una vez con
`sin_info_censo=1` y `estrato`, `va_ee` y `personas` faltantes. En las filas
observadas `sin_info_censo=0`, incluso cuando estrato o energía son faltantes.
Ausencia de información municipal no significa cero personas.

## Controles y salidas

- Se comprueba la unicidad de las llaves de hogares y viviendas, permitiendo
  componentes faltantes como en los cruces originales.
- Se exige que la suma sobre `va_ee` reproduzca exactamente la base anterior
  por municipio y estrato, incluyendo categorías faltantes.
- Se comprueba que todos los códigos censales estén en DIVIPOLA y que todos
  los municipios del catálogo aparezcan en el resultado.
- Los cruces, códigos observados y controles se muestran en los resultados
  de Stata; el script no genera un archivo `.log`.
- Los cruces con hogares y personas usan `keep(match) nogen`: los registros
  sin coincidencia se descartan directamente, sin generar reportes auxiliares.
- Los municipios sin conteos se identifican mediante `sin_info_censo` en la
  base final y se listan en Stata; no se exporta un CSV adicional.

La base anterior no se sobrescribe. La nueva base sí se
reemplaza al ejecutar nuevamente el script. Si falla un control, revisar
los resultados de Stata: una salida de una ejecución anterior no prueba que
la nueva terminó.

## Validación ejecutada el 14 de octubre de 2026

Stata procesó los 33 archivos departamentales de cada tipo (incluyendo Bogotá)
y completó todos los controles. La nueva base tiene 9.155 filas y los 1.122
códigos del catálogo DIVIPOLA; ningún municipio quedó sin información.
Al sumar las categorías de `va_ee`, los 8.361 conteos por municipio y estrato
coinciden exactamente con la salida anterior, que se mantuvo intacta.

Los cruces vincularon 44.164.417 personas. Se excluyeron 2.590.164 viviendas
sin coincidencia con hogares, siguiendo el procedimiento original. No hubo
hogares sin vivienda ni personas sin hogar vinculado en los cruces ejecutados.
Los códigos observados de `va_ee` fueron 1, 2 y faltante.

## Cambios del 15 de octubre de 2026

- Se retiró la generación de los reportes CSV de cruces y municipios sin datos.
- Se eliminaron los dos reportes CSV anteriores; no se borraron las fuentes
  censales ni las bases finales. El `.log` residual no pudo eliminarse porque
  otro proceso lo mantiene abierto; su eliminación queda pendiente hasta
  que se libere el archivo. El script ya no lo genera.
- Se simplificaron los cruces para conservar coincidencias directamente.
- Se trasladó este plan a `scripts/planes`, separado del código ejecutable.
- Se verificó estáticamente que no quedan instrucciones de exportación de
  reportes ni de registro en `.log`. No se repitió el procesamiento nacional:
  estos cambios conservan los mismos registros coincidentes y conteos.
