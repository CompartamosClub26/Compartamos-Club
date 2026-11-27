# Plan de pruebas de seguridad — MVP Buscar pareja Bogotá

Estado: plan preparado; **no ejecutado contra una base de datos**.
Alcance: validación previa a habilitar usuarios reales.

## Preparación
- Usar un entorno Supabase de pruebas, nunca cuentas reales.
- Crear dos miembros de prueba (A y B), un Director de prueba y un administrador técnico de prueba.
- No crear roles privilegiados en producción ni sembrar consentimientos legales provisionales.
- Registrar resultado, fecha y evidencia de cada caso.

## Matriz de pruebas

| ID | Actor | Acción | Resultado esperado |
|---|---|---|---|
| SEC-01 | Miembro A | Consultar su perfil | Solo ve su propio perfil. |
| SEC-02 | Miembro A | Consultar/editar perfil de B | Cero filas o acceso denegado. |
| SEC-03 | Miembro A | Insertar perfil con estado aprobado o teléfono verificado | Rechazado por política RLS. |
| SEC-04 | Miembro A | Cambiar estado, revisión o verificación de su perfil | Rechazado por trigger/permisos. |
| SEC-05 | Miembro A | Editar intereses mientras su perfil está pendiente | Rechazado por RLS. |
| SEC-06 | Miembro A | Aceptar documento no vigente o de tipo no permitido | Rechazado por RLS. |
| SEC-07 | Miembro A | Alterar aceptado_en o borrar aceptación | Rechazado por privilegios. |
| SEC-08 | Miembro A | Retirar consentimiento vigente | Solo puede establecer retirado_en; no revertirlo. |
| SEC-09 | Miembro A | Ejecutar moderacion_cola | Acceso denegado. |
| SEC-10 | Administrador técnico | Leer perfiles o ejecutar moderación | Acceso denegado; sin datos personales. |
| SEC-11 | Director | Consultar moderacion_cola | Solo datos mínimos de solicitudes pendientes. |
| SEC-12 | Director | Aprobar perfil sin teléfono verificado o sin cuatro consentimientos vigentes | Rechazado. |
| SEC-13 | Director | Aprobar/rechazar/suspender fuera de transición permitida | Rechazado. |
| SEC-14 | Director | Moderar su propio perfil | Rechazado. |
| SEC-15 | Anónimo | Consultar perfiles, roles o auditoría | Sin acceso. |

## Criterios para cerrar
1. Todas las pruebas SEC-01 a SEC-15 pasan en entorno aislado.
2. Confirmar RLS habilitado y revisar políticas efectivas, GRANT/REVOKE y funciones SECURITY DEFINER.
3. Confirmar que las funciones privilegiadas tienen `search_path` fijado y ejecución revocada a `public` y `anon`.
4. Revisar que no existan rutas, vistas o RPC alternativas que expongan perfiles al administrador técnico.
5. Ejecutar pruebas de regresión, typecheck y build del frontend integrado.
6. Adjuntar evidencia antes de aprobar la integración.

## Observaciones de alcance
- Las pruebas de políticas no se consideran aprobadas por el hecho de que CI de TypeScript esté verde.
- La autenticación OTP de correo no equivale a verificación telefónica.
- No cargar datos reales ni habilitar registro público hasta cerrar esta matriz.
