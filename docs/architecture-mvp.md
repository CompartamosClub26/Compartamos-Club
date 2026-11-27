# Compartamos Club — base de implementación MVP

## Alcance
Piloto exclusivo de Buscar pareja en Bogotá. No incluye feed, grupos, pagos, publicación pública, emparejamiento automático ni acceso público a perfiles.

## Modelo de datos
La migración `supabase/migrations/0001_mvp_profiles_consents.sql` crea:
- `public.member_profiles`: perfil privado, ciudad Bogotá, fecha de nacimiento para validar mayoría de edad, intereses, estado de revisión.
- `public.member_consents`: registro versionado de aceptaciones.
- `private.staff_roles`: roles asignados fuera del cliente.
- `private.audit_events`: bitácora interna.

## Separación de funciones
- Miembro: consulta y edita su propio perfil; nunca decide su estado de revisión.
- Director: puede consultar perfiles y revisar estados.
- Administrador técnico: no obtiene acceso a datos personales ni a moderación.
- Ningún usuario puede asignarse roles desde el cliente.

## Seguridad y limitaciones conocidas
1. El Director debe recibir el rol mediante una operación administrativa segura ejecutada por el propietario/operador de Supabase. No se crea una cuenta privilegiada por defecto.
2. No se almacenan documentos oficiales, selfies ni fotografías de verificación en esta primera migración.
3. El formulario actual solo recoge rango de edad. Para validar realmente mayoría de edad debe añadirse fecha de nacimiento y enviarse al servidor; no basta con confiar en el rango elegido por el usuario.
4. La migración debe revisarse y ejecutarse en el proyecto Supabase correcto antes de habilitar registros reales.
5. La función `private.is_director()` evita conceder permisos a un rol técnico. La asignación de Director queda fuera de las rutas públicas.

## Verificación
Pendiente ejecutar la migración en el proyecto de destino y realizar pruebas de RLS con tres identidades separadas: miembro A, miembro B y Director; además verificar que un administrador técnico no puede consultar perfiles.
