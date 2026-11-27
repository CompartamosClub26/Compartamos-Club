# Estado técnico — Compartamos Club MVP

Actualizado: 27-11-2026

## Alcance aprobado
Piloto exclusivo: Buscar pareja en Bogotá. No incluye feed, grupos, pagos, publicación pública, emparejamiento automático ni acceso público a perfiles.

## Código portable en GitHub
Repositorio: `CompartamosClub26/Compartamos-Club`.

Ramas y solicitudes:
- `work/audit-and-ci-hardening`: PR #1, abierta y en borrador.
- `work/consent-retirement-hardening`: PR #2, abierta y en borrador; apilada sobre PR #1.
- `work/integration-security-review`: PR #3, abierta y en borrador; consolida los cambios de seguridad y pruebas sobre la rama de auditoría.
- `main` permanece intacta; no se ha integrado ninguna de estas ramas.

Módulos preparados:
- Cliente Supabase de navegador: `src/lib/supabase.ts`.
- Autenticación OTP por correo: `src/lib/auth.ts`.
- Componente React de acceso por correo y OTP: `src/components/EmailCodeForm.tsx`.
- Validación y alta transaccional de perfil: `src/lib/perfil.ts`.
- Callback de autenticación: `src/lib/auth-callback.ts`.
- Migraciones SQL 0001 a 0011 en la rama de integración.
- Pruebas unitarias, pruebas de contrato de migraciones y batería SQL de roles/RLS/transiciones.
- Workflow PostgreSQL aislado para aplicar migraciones en orden y ejecutar regresiones.

El repositorio no contiene el árbol completo de la aplicación Lovable. Los módulos aún no están integrados en rutas reales del sitio.

## Validación automatizada
HEAD validado: `3ddb7710f58eb1a8963a1cd7f2efc989744fb475`.
- CI de Vitest y TypeScript: éxito.
- PostgreSQL 16 aislado: éxito; las migraciones 0001–0011 se aplicaron en orden.
- La batería SQL cubre envío de perfil, privacidad entre miembros, permisos del Director y administrador técnico, auto-moderación, aprobación condicionada, cambios de estado, congelación de datos y retiro irreversible de consentimientos.
- El entorno de prueba usa un shim mínimo de `auth.uid()`; no sustituye una validación en la instancia Supabase activa.
- No se ha ejecutado un build completo del sitio ni una prueba end-to-end con cuentas reales.

## Estado de Supabase activo
La base vinculada al proyecto Lovable está habilitada y usa PostgreSQL/Supabase.

Inspección de solo lectura del 27-11-2026:
- Existen las siete tablas previstas: `public.profiles`, `public.profile_interests`, `public.profile_goals`, `public.consent_documents`, `public.user_consents`, `private.user_roles` y `private.audit_log`.
- RLS aparece habilitado en las siete tablas.
- `FORCE ROW LEVEL SECURITY` aparece desactivado en las siete.
- No se encontró el esquema estándar `supabase_migrations` ni su tabla de historial de migraciones de aplicación. La tabla `auth.schema_migrations`, si se consulta, corresponde al esquema Auth y no debe confundirse con el historial de migraciones de este proyecto.
- La inspección se detuvo al alcanzarse el límite temporal de consultas de base de datos del plan gratuito. Quedaron pendientes la lectura de políticas efectivas, privilegios de tabla/columna, ACL de funciones y triggers de la instancia activa.

Las consultas anteriores registraron que la migración 0001 fue aplicada y que la 0002 estaba pendiente; esa referencia histórica no sustituye la verificación actual. La existencia de tablas y el indicador RLS habilitado no demuestran qué migraciones, políticas o funciones están activas hoy.

**Ninguna migración 0005–0011 de la rama de integración se ha aplicado a Supabase activo.** No se han ejecutado escrituras ni cambios de esquema en esa base durante esta revisión.

## Separación de funciones prevista
- Miembro: opera sobre su propio perfil y consentimientos.
- Director: consulta una cola reducida mediante función protegida, verifica teléfono y resuelve estados; no puede moderar su propio perfil.
- Administrador técnico: no debe tener lectura de perfiles ni permisos de moderación.
- No existe un Director sembrado automáticamente. La asignación inicial requiere una operación controlada del propietario después de verificar la identidad.

## Pendientes bloqueantes antes de registrar usuarios
1. Reanudar la inspección de solo lectura en Supabase activo cuando vuelva a estar disponible el acceso: políticas RLS, GRANT/REVOKE, privilegios de columna, ACL y definiciones de funciones/triggers.
2. Determinar el estado real de cada migración en la base activa sin inferirlo por la mera existencia de tablas.
3. Preparar una secuencia de aplicación compatible con el historial real de Supabase; no aplicar automáticamente las migraciones 0005–0011.
4. Ejecutar pruebas con sesiones reales aisladas: dos miembros, Director y administrador técnico.
5. Aprobar textos y versiones jurídicas de condiciones, convivencia, privacidad y mayoría de edad; después generar hashes reales y sembrar los documentos.
6. Integrar OTP y perfil en rutas reales sin reemplazar ni rediseñar páginas existentes.
7. Configurar variables públicas de Supabase y plantilla OTP; nunca exponer service_role ni secretos.
8. Implementar el panel privado del Director y la verificación manual.
9. Ejecutar pruebas integrales, build y revisión móvil/escritorio.

## Límites operativos
- El proyecto Lovable original permanece sin cambios de código desde el 15-11-2026; el intento de usar su agente fue rechazado por saldo de créditos agotado.
- No se han creado perfiles ni roles privilegiados de prueba en Supabase activo.
- No se han publicado cambios, activado pagos, invitado usuarios ni contactado terceros.
- No registrar personas reales hasta cerrar las verificaciones de seguridad, autenticación y consentimiento.
- No almacenar fotos, selfies ni documentos oficiales en esta fase.
