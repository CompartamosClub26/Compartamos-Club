# Estado técnico del workspace portable

Fecha: 27-11-2026

## Código incorporado
- Cliente Supabase de navegador.
- Funciones de registro, inicio/cierre de sesión, recuperación y cambio de contraseña.
- Validación y creación transaccional del perfil de pareja Bogotá.
- Migración correctiva 0002: inserción de perfil endurecida, roles/auditoría no expuestos y RPC transaccional `crear_perfil`.
- Pruebas unitarias de validación de entrada.

## No confundir
Este workspace es una base portable y no contiene el árbol completo de la aplicación Lovable. Los módulos de autenticación no están conectados todavía a la pantalla existente `/registro`. La migración 0002 está versionada, pero requiere aplicarse y verificarse en Supabase antes de que la función RPC esté disponible.

## Próximos pasos técnicos
1. Aplicar migración 0002 en Supabase y comprobar RLS/grants con tres identidades.
2. Añadir callback de confirmación y pantallas de login/recuperación.
3. Integrar el registro existente al flujo de autenticación y persistencia sin modificar el diseño visual aprobado.
4. Configurar las dos variables públicas de Supabase en el entorno frontend.
5. Ejecutar `npm install`, `npm test`, `npm run typecheck` y build de la app integrada.
6. Preparar panel del Director tras completar las pruebas de separación de roles.
