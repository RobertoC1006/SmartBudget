# Frontend SmartBudget+

Interfaz web multi-vista que consume directamente la API de SmartBudget+. Se construyó con HTML 5, Bootstrap 5.3, JavaScript nativo y una paleta minimalista en tonos verde/blanco.

## Estructura principal

- `index.html`: landing page pública.
- `pages/login.html` y `pages/register.html`: autenticación de usuarios.
- `pages/dashboard.html`: resumen financiero (presupuesto, smartscore, alertas y gastos recientes).
- `pages/budget.html`: creación/actualización del presupuesto mensual.
- `pages/expenses.html`: registros manuales y carga OCR de gastos, además del historial.
- `pages/smartscore.html`: histórico, recalculo del SmartScore y alertas activas.
- `pages/simulator.html`: simulador “¿Y si...?” con escenarios y ajustes personalizados.
- `pages/goals.html`: metas/retos, progreso y sugerencias dinámicas.

### Assets

- `assets/css/styles.css`: estilos personalizados (paleta, tarjetas, utilidades).
- `assets/js/core.js`: utilidades compartidas (autenticación, fetch, helpers, alertas).
- Resto de scripts en `assets/js/…`: lógica específica para cada vista.

## Cómo ejecutar el frontend

Sirve los archivos de manera estática (por ejemplo con `python -m http.server`):

```bash
cd Frontend
python -m http.server 9000
```

Luego abre `http://127.0.0.1:9000` en el navegador.

> **Importante**: el archivo `core.js` está configurado para apuntar a `http://127.0.0.1:8000/api`, por lo que el backend debe estar activo en ese host/puerto. Si se despliega en otra URL, ajusta `API_BASE_URL` en `assets/js/core.js`.

## Flujo de autenticación

1. Registra un usuario en `pages/register.html`.
2. Inicia sesión en `pages/login.html`. El `access_token` y `refresh_token` se guardan en `localStorage`.
3. Todas las páginas bajo `pages/` invocan `SB.initProtectedPage()` para validar sesión y cargar datos del backend.
4. El botón “Cerrar sesión” elimina tokens y redirige automáticamente.

## Integración con la API

Los formularios y tablas ya consumen los endpoints del backend:

- Autenticación: `/api/auth/register`, `/api/auth/login`, `/api/auth/me`.
- Presupuestos: `/api/budgets/`, `/api/budgets/current`.
- Gastos: `/api/expenses/` (manual), `/api/expenses/upload` (OCR).
- SmartScore y alertas: `/api/smartscore/recalculate`, `/api/smartscore/history`, `/api/alerts/`.
- Simulador: `/api/simulator/`.
- Metas: `/api/goals/`, `/api/goals/suggestions`, `/api/goals/{goal_id}/progress`.

Todas las peticiones se realizan mediante `SB.request`, que añade automáticamente el token `Bearer` y maneja respuestas JSON.

## Personalización

- Modifica la paleta de colores en `styles.css` si deseas nuevos tonos.
- Ajusta el `API_BASE_URL` en `core.js` para apuntar a entornos de desarrollo/pruebas.
- Los componentes (alertas, tablas, formularios) usan clases Bootstrap, por lo que puedes añadir utilidades o componentes extra con facilidad.

Con esto tendrás el frontend conectado y listo para iterar sobre nuevas funciones visuales. Mantén el backend levantado para ver los datos en tiempo real. 

