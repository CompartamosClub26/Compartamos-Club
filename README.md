# Compartamos Club — MVP Buscar pareja Bogotá

Workspace portable de implementación. El proyecto original de Lovable se conserva como origen visual y no se sobrescribe desde este repositorio.

## Módulos preparados
- Cliente Supabase para navegador.
- Autenticación por código de un solo uso enviado al correo (OTP).
- Componente React de acceso por correo y OTP.
- Validación de datos y alta transaccional mediante RPC `crear_perfil`.
- Migraciones SQL para perfiles, intereses, objetivo pareja, consentimientos, roles y auditoría.
- Pruebas unitarias iniciales del esquema de perfil.

## Configuración
Variables públicas requeridas:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

En la plantilla de correo de autenticación de Supabase debe configurarse la entrega del token OTP (por ejemplo, `{{ .Token }}`) si se utiliza el formulario de código. Configurar también las URL de redirección permitidas para el dominio de prueba. No guardar claves `service_role`, contraseñas ni secretos en el navegador, GitHub o variables `VITE_*`.

## Estado y límites
Este repositorio no contiene todavía el árbol completo de la aplicación Lovable. Los módulos son preparación portable y aún deben integrarse en rutas reales. No se han ejecutado localmente tests, typecheck ni build; el workflow de CI los ejecutará al recibir un push o pull request.

La migración `0001` fue aplicada a la base vinculada al proyecto Lovable. La migración `0002` está versionada pero pendiente de aplicación y verificación. No registrar miembros reales hasta validar RLS, permisos, autenticación y documentos de consentimiento.

## Seguridad operativa
- No incluir claves privadas ni secretos en el frontend.
- No crear roles Director automáticamente.
- No almacenar fotos, selfies ni documentos oficiales en esta fase.
- No publicar, activar pagos ni invitar usuarios sin aprobación expresa.
