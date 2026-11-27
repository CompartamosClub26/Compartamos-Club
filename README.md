# Compartamos Club — MVP Buscar pareja Bogotá

Workspace portable de implementación. El proyecto original de Lovable se mantiene como origen del diseño y no se sobrescribe desde este repositorio.

## Implementado
- Migración base del modelo de perfiles, intereses, objetivos, consentimientos, roles internos y auditoría.
- Cliente Supabase para frontend, con variables de entorno públicas.
- Flujo de autenticación por correo y contraseña y creación de perfil pendiente en módulos independientes.
- Migración correctiva de endurecimiento de RLS y transición de perfil.

## Configuración local
Variables necesarias:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

No guardar claves `service_role`, contraseñas ni secretos en el navegador, GitHub o variables `VITE_*`.

## Pendiente de integración
Este repositorio aún no contiene el árbol completo de la aplicación Lovable. Los módulos son portables y deben incorporarse al código original, regenerar rutas TanStack y ejecutar las pruebas/build antes de aceptar cambios en el proyecto visual.
