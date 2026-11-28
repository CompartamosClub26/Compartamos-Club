# Mapa de integración — Compartamos Club / MVP Buscar pareja Bogotá

Fecha: 27-11-2026  
Estado: auditoría de solo lectura y plan técnico; no habilita implementación ni despliegue.

## 1. Fuentes contrastadas

- Proyecto Lovable original: `8e498b0d-9873-4052-b258-d4775c2429cc`, commit `d6f11d5711d56d64bed1e6c2a8eeb642135e730a`.
- Repositorio portable: `CompartamosClub26/Compartamos-Club`, rama base de este documento `work/integration-security-review`.
- Plan técnico aprobado archivado en el proyecto Lovable: `.lovable/plan/módulo-1-auth-profiles-diseño-técnico-ejecutable-revisión-cr-2026-11-14.md`.

## 2. Hallazgo principal: son dos árboles de código diferentes

El proyecto Lovable original sí contiene la aplicación completa. Usa TanStack Start, TanStack Router con rutas por archivo, TypeScript, Vite y React. Rutas actuales:
- `/`
- `/registro`
- `/condiciones`
- `/convivencia-seguridad`
- `/privacidad`

El repositorio GitHub portable es un conjunto separado de módulos de preparación. Su `main` no contiene el árbol de la aplicación Lovable ni sus rutas, `vite.config.ts`, `src/App.tsx` o `src/main.tsx`. El framework de rutas del original es TanStack Router, no React Router ni un enrutador convencional basado en `App.tsx`.

**Consecuencia:** no copiar archivos a ciegas ni intentar sustituir la aplicación. La integración debe hacerse como rutas y funciones aditivas de TanStack Start, respetando el diseño y la estructura original.

## 3. Elementos que deben preservarse sin cambios

- Portada `/`.
- Formulario demostrativo `/registro` y su comportamiento de no guardar datos.
- `src/lib/registro.ts` y el catálogo actual de intereses/modalidades.
- Páginas legales existentes y sus avisos de borrador.
- Árbol de rutas generado `src/routeTree.gen.ts`: se regenera con TanStack Router; nunca editarlo manualmente.
- Estilos, componentes UI, pruebas y recursos visuales existentes.

No se ha editado el proyecto Lovable durante esta auditoría.

## 4. Diferencias funcionales que impiden conectar directamente el registro actual

El formulario existente:
- permite escribir cualquier ciudad;
- permite elegir una o varias modalidades (amistad, actividades y pareja);
- presenta un resumen local de demostración;
- declara expresamente que no envía ni guarda datos.

El piloto autorizado:
- es exclusivamente **Buscar pareja en Bogotá**;
- requiere cuenta por código de correo;
- exige cuatro consentimientos vigentes (condiciones, convivencia, privacidad y mayoría de edad);
- exige verificación telefónica manual por el Director antes de aprobar;
- requiere revisión del Director;
- no permite al administrador técnico consultar perfiles ni moderar.

Por tanto, el registro actual no debe convertirse directamente en el alta real. Debe mantenerse como demostración y añadirse un flujo separado y autenticado, con ciudad Bogotá y objetivo pareja fijados en servidor.

## 5. Arquitectura de integración recomendada

Seguir el plan técnico archivado del proyecto Lovable:
- nuevas rutas aditivas `/acceso`, `/_authenticated/mi-perfil` y `/_authenticated/moderacion`;
- proteger rutas y operaciones con middleware/server functions de TanStack Start;
- validar entradas con Zod tanto en cliente como en servidor;
- mantener autorización y transiciones en PostgreSQL/RLS y funciones SQL; nunca confiar en roles enviados por el navegador;
- usar OTP de correo como acceso, pero no confundirlo con la verificación telefónica;
- el Director verifica el teléfono manualmente y registra el método `manual`;
- el administrador técnico no obtiene lectura de perfiles ni acceso a la cola;
- no implementar fotos, selfies, chats, pagos, matching automático ni publicación en esta fase.

### Decisión arquitectónica pendiente

Los módulos portables actuales usan `@supabase/supabase-js` desde el navegador y llaman RPC directamente. El plan de integración del proyecto original especifica que las escrituras sensibles deben pasar por `createServerFn`, middleware de sesión y validación de servidor, con RLS como defensa adicional.

Antes de portar código, elegir y documentar una sola arquitectura coherente con el backend activo (Lovable Cloud/Supabase PostgreSQL) y adaptar los módulos a TanStack Start. No mezclar dos flujos de sesión ni importar el cliente administrador en el navegador. Nunca exponer `service_role`, secretos ni claves privadas.

## 6. Backend y seguridad: bloqueos vigentes

La rama `work/integration-security-review` contiene migraciones 0001–0011 y pruebas que pasaron en PostgreSQL 16 aislado. Esto no demuestra que esas migraciones estén aplicadas o sean seguras en la base activa.

La inspección previa de solo lectura de Supabase activo detectó:
- políticas amplias `interests_self_all` y `goals_self_all` que no limitan cambios por estado;
- políticas de perfil y trigger que no corresponden a todos los endurecimientos de la rama;
- ausencia de un Director y un administrador técnico asignados;
- ausencia del historial estándar `supabase_migrations`, por lo que no se puede inferir la secuencia aplicada solo por la existencia de tablas;
- revisión de privilegios de columna/ACL incompleta por límite temporal del plan gratuito.

No aplicar automáticamente las migraciones 0001–0011 ni ejecutar una migración aislada. Primero reconstruir el estado real de esquema, políticas, grants, columnas, triggers, funciones y roles. Después diseñar una secuencia de actualización compatible y probarla en un entorno aislado restaurable.

## 7. Secuencia propuesta de trabajo

1. Cerrar inventario y compatibilidad de esquema: comparar tablas/columnas/tipos/funciones activas con migraciones versionadas.
2. Resolver la decisión de arquitectura TanStack Start + backend; adaptar OTP y perfil a server functions.
3. Diseñar y probar las nuevas rutas sin tocar las rutas actuales.
4. Aprobar legalmente los cuatro documentos y versiones; generar hashes reales solo después de aprobación.
5. Preparar bootstrap controlado del primer Director, con identidad verificada, separado del administrador técnico.
6. Ejecutar pruebas integrales con cuentas aisladas: miembro A, miembro B, Director y administrador técnico.
7. Verificar build, typecheck, lint, pruebas, navegación y experiencia móvil/escritorio.
8. Revisar evidencia y autorizar por separado cualquier migración activa, integración a `main`, conexión con Lovable o publicación.

## 8. Criterios de salida del piloto

No habilitar miembros reales hasta cumplir todo:
- OTP probado con plantilla y límites de envío configurados.
- Consentimientos aprobados y versionados.
- Verificación telefónica manual operativa y auditable.
- Aislamiento A/B confirmado en la base activa.
- Director puede moderar solo terceros y ve únicamente la cola mínima.
- Administrador técnico no puede leer perfiles ni ejecutar moderación.
- Perfil pendiente no puede editar intereses/objetivos ni datos personales.
- Registro, revisión, aprobación, rechazo, retiro de consentimiento y baja probados de extremo a extremo.
- Sin exposición de secretos y sin cambios no autorizados al prototipo original.

## 9. Estado y límites de esta revisión

- Solo se leyeron archivos, metadatos y estructura del proyecto Lovable y GitHub.
- No se editaron archivos del proyecto Lovable.
- No se ejecutaron escrituras, DDL ni migraciones en Supabase activo.
- No se fusionaron pull requests, no se publicó el producto y no se contactó a terceros.
- Este documento es una guía de integración, no una certificación de seguridad ni una autorización para habilitar usuarios.
