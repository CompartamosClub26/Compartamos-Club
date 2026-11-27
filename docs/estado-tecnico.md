# Estado técnico — Compartamos Club MVP

Actualizado: 27-11-2026

## Trabajo portable incorporado
- Cliente Supabase de navegador: `src/lib/supabase.ts`.
- Autenticación por código de un solo uso enviado al correo: `src/lib/auth.ts`.
- Componente accesible de acceso por correo y OTP: `src/components/EmailCodeForm.tsx`.
- Validación y alta transaccional del perfil de pareja Bogotá: `src/lib/perfil.ts`.
- Callback y lectura de sesión: `src/lib/auth-callback.ts`.
- Migración base: `supabase/migrations/0001_mvp_profiles_consents.sql`.
- Migración correctiva: `supabase/migrations/0002_profile_insert_hardening.sql`.
- Pruebas de validación de perfil: `tests/perfil.test.ts`.

## Límite operativo verificado
El proyecto Lovable original sigue sin cambios de código desde el último commit de noviembre 15. La llamada al agente Lovable del 27-11 fue rechazada por el workspace: saldo de créditos agotado. Por eso estos módulos no están integrados a las rutas reales ni se han ejecutado allí tests, lint, typecheck o build.

La base Supabase ya tiene las siete tablas de la migración 0001, según la consulta anterior. La migración 0002 está versionada, pero no se pudo aplicar ni verificar en la base activa por el límite temporal de consultas SQL de Lovable.

## Diferencias que aún deben resolverse antes de activar
1. El diseño aprobado recomienda OTP por correo sin contraseña; el módulo portable sigue esta decisión.
2. Los documentos jurídicos de consentimiento aún no tienen versiones/hash aprobados; no se deben inventar ni sembrar.
3. La primera identidad Director no está definida/provisionada; no se asignó automáticamente.
4. La migración 0001 debe revisarse contra el esquema exacto aprobado: especialmente transiciones, campos que la cola del Director puede ver, separación de roles y reglas de consentimiento.
5. La migración 0002 debe aplicarse y probarse antes de usar `crear_perfil`.
6. No hay aún pruebas reales A/B, pruebas de escalamiento de roles ni validación de correo en entorno configurado.

## Siguiente secuencia
1. Reanudar en Lovable cuando el workspace permita enviar construcción: integrar OTP en `/acceso`, rutas protegidas `/mi-perfil` y `/moderacion`, sin alterar las páginas actuales.
2. Aplicar migración correctiva en base activa y verificar RLS/GRANT con sesiones distintas.
3. Configurar URL y anon key como variables públicas del proyecto; nunca service_role en frontend.
4. Crear documentos de consentimiento versionados tras revisión jurídica.
5. Probar registro, confirmación OTP, aislamiento A/B, rol Director y denegación total al administrador técnico.
6. Ejecutar suite completa, lint, typecheck y build. No declarar listo antes de ello.

## Restricciones de despliegue
Sin publicación, cobros, invitaciones, usuarios reales ni presentación automática. Los módulos son código de preparación, no un piloto operativo.
