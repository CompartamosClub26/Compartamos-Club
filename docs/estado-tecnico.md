# Estado técnico — Compartamos Club MVP

Actualizado: 27-11-2026

## Alcance aprobado
Piloto exclusivo: Buscar pareja en Bogotá. No incluye feed, grupos, pagos, publicación pública, emparejamiento automático ni acceso público a perfiles.

## Código portable en GitHub
Repositorio: `CompartamosClub26/Compartamos-Club`.
Rama de trabajo: `work/audit-and-ci-hardening`.
Solicitud de integración: PR #1, abierta y en borrador. No está integrada en `main`.

Módulos preparados:
- Cliente Supabase de navegador: `src/lib/supabase.ts`.
- Autenticación OTP por correo: `src/lib/auth.ts`.
- Componente React de acceso por correo y OTP: `src/components/EmailCodeForm.tsx`.
- Validación y alta transaccional de perfil: `src/lib/perfil.ts`.
- Callback de autenticación: `src/lib/auth-callback.ts`.
- Migraciones SQL 0001 a 0004.
- Pruebas unitarias iniciales de validación del perfil.

El repositorio no contiene el árbol completo de la aplicación Lovable. Los módulos aún no están integrados en rutas reales del sitio.

## Validación automatizada
- En la rama de trabajo, el workflow CI del 27-11-2026 terminó en éxito: instalación de dependencias, pruebas y typecheck.
- En `main`, la ejecución anterior falló durante la instalación de dependencias; las pruebas y el typecheck fueron omitidos.
- El CI verde valida el conjunto portable aislado; no demuestra integración con la aplicación Lovable ni seguridad real de la base de datos.
- No se ha ejecutado un build completo del sitio ni una prueba end-to-end con cuentas distintas.

## Estado de Supabase
La documentación y las consultas anteriores registran que la migración 0001 fue aplicada a la base vinculada al proyecto Lovable y que existen las siete tablas previstas. La migración 0002 quedó pendiente de aplicación y verificación. Las migraciones 0003 y 0004 están versionadas en la rama de trabajo, pero no se ha confirmado su aplicación en la base activa.

La consulta más reciente volvió a ser rechazada por el límite temporal de acciones de base de datos del plan gratuito. Por tanto, no se debe asumir que las políticas y funciones añadidas en 0002–0004 estén activas.

## Separación de funciones prevista
- Miembro: opera sobre su propio perfil y consentimientos.
- Director: consulta una cola reducida mediante función protegida, verifica teléfono y resuelve estados.
- Administrador técnico: no debe tener lectura de perfiles ni permisos de moderación.
- No existe un Director sembrado automáticamente. La asignación inicial requiere una operación controlada del propietario después de verificar la identidad.

## Pendientes bloqueantes antes de registrar usuarios
1. Revisar las migraciones SQL 0002–0004 y resolver cualquier observación de seguridad antes de aplicarlas.
2. Aplicar las migraciones pendientes en la base correcta y verificar RLS, GRANT/REVOKE y funciones con sesiones de prueba.
3. Probar aislamiento entre dos miembros, Director y administrador técnico.
4. Aprobar textos y versiones jurídicas de condiciones, convivencia, privacidad y mayoría de edad; después generar hashes reales y sembrar los documentos.
5. Integrar OTP y perfil en rutas reales sin reemplazar ni rediseñar páginas existentes.
6. Configurar variables públicas de Supabase y plantilla OTP; nunca exponer service_role ni secretos.
7. Implementar el panel privado del Director y la verificación manual.
8. Ejecutar pruebas integrales, build y revisión móvil/escritorio.

## Límites operativos
- El proyecto Lovable original permanece sin cambios de código desde el 15-11-2026; el intento de usar su agente fue rechazado por saldo de créditos agotado.
- No se han creado perfiles ni roles privilegiados de prueba.
- No se han publicado cambios, activado pagos, invitado usuarios ni contactado terceros.
- No registrar personas reales hasta cerrar las verificaciones de seguridad, autenticación y consentimiento.
- No almacenar fotos, selfies ni documentos oficiales en esta fase.
