# Compartamos Club — implementación MVP Buscar pareja Bogotá

## Estado de avance — 27 de noviembre de 2026
- Migración SQL creada en `supabase/migrations/0001_mvp_profiles_consents.sql`.
- La migración se ejecutó correctamente en la base Supabase del proyecto Lovable.
- Confirmación obtenida: existen siete tablas de negocio: `profiles`, `profile_interests`, `profile_goals`, `consent_documents`, `user_consents`, `private.user_roles` y `private.audit_log`.
- Las funciones de servidor para cola de moderación, verificación telefónica, envío a revisión y resolución de revisión fueron creadas.
- No se crearon cuentas de prueba, perfiles ni roles privilegiados.
- La comprobación adicional de RLS quedó pendiente porque Lovable alcanzó el límite temporal de consultas SQL del plan gratuito (indicó 22 minutos de espera).
- Después de ejecutar la migración se endureció en el archivo fuente la política de inserción para impedir que un usuario inyecte campos de revisión/verificación. Ese ajuste todavía debe aplicarse a la base activa cuando se restablezca el límite SQL.

## Alcance
Piloto exclusivo de Buscar pareja en Bogotá. No incluye feed, grupos, pagos, publicación pública, emparejamiento automático ni acceso público a perfiles.

## Modelo de datos
- `public.profiles`: alias, ciudad Bogotá, rango de edad, estado de revisión y marcas de verificación.
- `public.profile_interests` y `public.profile_goals`: catálogo de intereses y objetivo único pareja.
- `public.consent_documents` y `public.user_consents`: versiones y aceptaciones.
- `private.user_roles`: únicamente Director y administrador técnico.
- `private.audit_log`: registro de cambios de estado y verificaciones.

## Separación de funciones
- Miembro: opera sobre su propio perfil y consentimientos.
- Director: consulta la cola reducida mediante función protegida, verifica teléfono y resuelve estados.
- Administrador técnico: no tiene lectura de perfiles ni permisos de moderación.
- No se asignó ningún Director automáticamente. La primera asignación requiere operación de propietario controlada después de verificar la identidad.
- No se exponen perfiles públicamente ni se permite matching automático.

## Funciones SQL creadas
- `public.moderacion_cola()`
- `public.enviar_revision()`
- `public.marcar_telefono_verificado(uuid, verification_method)`
- `public.resolver_revision(uuid, profile_status, text)`

La aprobación exige teléfono verificado y los cuatro consentimientos vigentes: condiciones, convivencia, privacidad y mayoría de edad.

## Pendientes técnicos antes de habilitar el flujo de usuarios
1. Aplicar el endurecimiento actualizado de la política `profiles_self_insert` a la base activa.
2. Verificar formalmente RLS en las siete tablas y los GRANT/REVOKE.
3. Probar aislamiento con dos miembros y Director; comprobar que administrador técnico no puede leer perfiles ni ejecutar moderación.
4. Sembrar documentos de consentimiento solo después de cerrar las versiones jurídicas.
5. Integrar autenticación de correo y rutas de perfil con el código React existente.
6. Implementar el panel privado del Director y el proceso de verificación manual.
7. Ejecutar lint, pruebas y build; revisar el sitio en móvil y escritorio.

## Seguridad / límites
- No almacenar documentos oficiales, selfies ni fotografías en esta primera fase.
- No registrar datos reales hasta cerrar las pruebas RLS.
- El rango de edad no es prueba suficiente de mayoría de edad; la declaración versionada de mayoría de edad será un consentimiento obligatorio.
- El Director debe asignarse desde operación administrativa segura. No existe usuario privilegiado preconfigurado.
- El administrador técnico no debe compartir cuenta ni rol con el Director.

## No realizado
No se publicaron cambios, no se activaron pagos, no se enviaron mensajes a terceros y no se crearon perfiles reales.
