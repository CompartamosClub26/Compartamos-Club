# Integración de autenticación y perfil

## Módulos preparados
- `src/lib/supabase.ts`: cliente de navegador con sesión persistente.
- `src/lib/auth.ts`: registro, inicio/cierre de sesión, recuperación y cambio de contraseña.
- `src/lib/perfil.ts`: creación transaccional de perfil, intereses, objetivo pareja, consentimientos, envío a revisión y lectura del perfil propio.

## Dependencia
Añadir `@supabase/supabase-js` a las dependencias del frontend.

## Variables
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Nunca colocar `service_role`, claves privadas ni contraseñas en variables `VITE_*`.

## Configuración Supabase Auth
1. Activar confirmación de correo.
2. Definir URL del sitio y redirecciones permitidas para `/auth/callback` y `/auth/reset-password`.
3. Configurar SMTP de producción antes de abrir registros.
4. Crear versiones finales de cuatro documentos de consentimiento obligatorios y sembrarlos en `consent_documents`; no insertar hashes ficticios.

## Flujo
Registro → confirmación de correo → inicio de sesión → creación de perfil Bogotá → envío a revisión → estado pendiente. No hay directorio público ni matching.

## Estado
Los módulos son portables y aún no están integrados en las rutas de la aplicación Lovable ni probados con build. No habilitar registros reales hasta incorporar dependencia, variables, callbacks, documentos legales y pruebas RLS.
