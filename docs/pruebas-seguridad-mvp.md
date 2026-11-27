# Plan de pruebas de seguridad — MVP Buscar pareja Bogotá

Estado: ejecutado en PostgreSQL 16 aislado mediante CI; **pendiente contrastar contra la base Supabase activa**.
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

## Casos adicionales detectados en revisión de migraciones
| ID | Actor | Acción | Resultado esperado |
|---|---|---|---|
| SEC-16 | Miembro | Enviar perfil borrador con intereses, objetivo pareja y cuatro consentimientos vigentes | Pasa a pendiente; el servidor fija enviado_en y limpia datos de revisión anteriores. |
| SEC-17 | Miembro | Enviar perfil incompleto o con consentimientos retirados/no vigentes | Rechazado por el trigger y la función. |
| SEC-18 | Miembro | Intentar pasar directamente de pendiente a aprobado, rechazado o suspendido | Rechazado. |
| SEC-19 | Miembro | Cambiar alias, ciudad o rango mientras está pendiente, suspendido o con baja solicitada | Rechazado. |
| SEC-20 | Miembro | Cambiar creado_en, titularidad o campos de verificación | Rechazado. |
| SEC-21 | Miembro | Editar datos personales de un perfil aprobado | Se devuelve a pendiente y se limpian los datos de revisión anteriores. |
| SEC-22 | Miembro | Reenviar un perfil rechazado | Solo pasa a pendiente si vuelve a cumplir todos los requisitos; se limpian los datos de revisión anteriores. |

La transición de envío se valida tanto en `public.enviar_revision()` como en el trigger de perfiles. Esto evita que el trigger bloquee el flujo legítimo y evita que una actualización directa eluda los requisitos del envío.

| SEC-23 | Miembro o Director | Intentar actualizar directamente el estado, revisión, verificación o marcas de tiempo del perfil | Rechazado por privilegios de columna; solo RPC autorizadas pueden hacerlo. |
| SEC-24 | Director | Intentar aprobar su propio perfil por RPC o actualización directa | Rechazado. |
| SEC-25 | Director | Consultar la cola cuando su propio perfil está pendiente | Su propio perfil no aparece en la cola. |
