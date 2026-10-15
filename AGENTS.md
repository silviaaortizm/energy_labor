# Organización de scripts y planes

- Mantener el código ejecutable del proyecto en `scripts/`, usando subcarpetas
  por tema cuando corresponda.
- Para cada script que se cree o modifique, crear o actualizar un plan Markdown
  en `scripts/planes/` con el mismo nombre base: por ejemplo,
  `extra scripts/Censo_Municipios_Estrato.do` corresponde a
  `planes/Censo_Municipios_Estrato.md`.
- Actualizar el mismo plan en cambios posteriores; no crear versiones fechadas
  separadas. Si dos scripts comparten nombre, reflejar sus subcarpetas dentro
  de `planes/` para evitar colisiones.
- Documentar la ruta del script, objetivo, entradas, procedimiento, salidas,
  validaciones realizadas y fecha de actualización. Distinguir comprobaciones
  ejecutadas de las pendientes y conservar resultados previos con su fecha.
- No generar logs ni archivos auxiliares de registros sin coincidencia para el
  script del Censo, salvo que la usuaria los solicite. Mantener las validaciones
  y conservar únicamente coincidencias en los cruces vivienda-hogar-persona.
