# SmartBudget+

Gestor de ahorros con backend en FastAPI y frontend estÃ¡tico (HTML + Bootstrap). Permite registrar presupuestos mensuales, cargar gastos (manuales u OCR), calcular el SmartScore financiero, simular escenarios â€œÂ¿Y siâ€¦?â€ y gestionar metas de ahorro con alertas inteligentes.

---

## Tabla de contenidos

1. [Arquitectura general](#arquitectura-general)
2. [Requisitos previos](#requisitos-previos)
3. [Preparar el entorno](#preparar-el-entorno)
4. [Backend (FastAPI)](#backend-fastapi)
   - [Ãrbol de directorios](#Ã¡rbol-de-directorios-backend)
   - [Variables de entorno](#variables-de-entorno)
   - [Migraciones y base de datos](#migraciones-y-base-de-datos)
   - [EjecuciÃ³n](#ejecuciÃ³n-backend)
   - [Resumen de endpoints](#resumen-de-endpoints)
5. [Frontend](#frontend)
6. [OCR y anÃ¡lisis de boletas](#ocr-y-anÃ¡lisis-de-boletas)
7. [Flujos funcionales](#flujos-funcionales)
8. [Testing manual recomendado](#testing-manual-recomendado)
9. [Notas y futuras mejoras](#notas-y-futuras-mejoras)

---

## Arquitectura general

- **Backend**: FastAPI + SQLAlchemy 2 + Pydantic v2. Define modelos ORM para usuarios, presupuestos, gastos, alertas, metas y snapshots de SmartScore. Incluye servicios para:
  - Autenticación con JWT (`passlib[bcrypt]` y `python-jose`).
  - Gestión de presupuestos y gastos manuales.
  - Calculo del SmartScore y generación de alertas.
  - Metas inteligentes y simulaciones de escenarios financieros.
  - Integración con automatizaciones externas (n8n) que envían resultados OCR ya estructurados.
- **Base de datos**: SQLite por defecto (`data/smartbudget.db`), fÃ¡cilmente configurable vÃ­a `DATABASE_URL`.
- **Frontend**: HTML estÃ¡tico + Bootstrap 5 + JavaScript nativo. Las vistas se sirven desde `Frontend/` y consumen la API vÃ­a `fetch`:
  - PÃ¡ginas independientes para login, registro, panel, presupuesto, gastos, smartscore, simulador, metas y perfil.
  - NavegaciÃ³n dinÃ¡mica segÃºn estado de sesiÃ³n.
- **OCR**: Delegado a un webhook de automatización (n8n) que recibe la boleta, ejecuta OCR donde prefieras y responde un payload listo para autocompletar los formularios.

---

## Requisitos previos

1. **Python 3.11+** (se probó con 3.13).
2. **Automatización OCR externa** (n8n self-hosted, n8n.cloud, Make, etc.) capaz de recibir archivos y responder JSON con `description`, `amount`, `category`, `expenseDate`, `rawText` y campos adicionales.
3. Node no es necesario; el frontend es estático.

---

## Preparar el entorno

```powershell
# 1) Crear entorno virtual
python -m venv .venv
.\.venv\Scripts\activate

# 2) Instalar dependencias
pip install --upgrade pip
pip install -r Backend/requirements.txt

# 3) Configurar variables (ver sección siguiente)
```

---

## Backend (FastAPI)
## Backend (FastAPI)

### Ãrbol de directorios (Backend/)

```
Backend/
â”œâ”€â”€ api/
â”‚   â”œâ”€â”€ main.py                # create_app() y registro de routers
â”‚   â”œâ”€â”€ dependencies.py
â”‚   â”œâ”€â”€ routes/
â”‚   â”‚   â”œâ”€â”€ auth.py
â”‚   â”‚   â”œâ”€â”€ budgets.py
â”‚   â”‚   â”œâ”€â”€ expenses.py
â”‚   â”‚   â”œâ”€â”€ smartscore.py
â”‚   â”‚   â”œâ”€â”€ simulator.py
â”‚   â”‚   â”œâ”€â”€ alerts.py
â”‚   â”‚   â””â”€â”€ goals.py
â”‚   â””â”€â”€ schemas/               # Pydantic models para requests/responses
â”œâ”€â”€ core/
â”‚   â”œâ”€â”€ config.py              # Settings centralizados (pydantic-settings)
â”‚   â”œâ”€â”€ security.py            # Hashing y JWT helpers
â”‚   â”œâ”€â”€ auth.py                # Servicios de usuarios
â”‚   â”œâ”€â”€ budgets.py, expenses.py, alerts.py, goals.py
â”‚   â”œâ”€â”€ simulator.py, smartscore.py
    ├── enums.py, etc.\r\nâ”œâ”€â”€ db/
â”‚   â”œâ”€â”€ session.py             # Engine + SessionLocal
â”‚   â”œâ”€â”€ base.py                # Declarative base
â”‚   â””â”€â”€ models.py              # ORM modelo relacional
â””â”€â”€ requirements.txt
```

### Variables de entorno

Usa `Backend/.env` (ya creado) o variables del entorno del sistema. Principales:

| Variable | DescripciÃ³n | Valor por defecto |
|----------|-------------|-------------------|
| `DATABASE_URL` | Cadena SQLAlchemy | `sqlite:///./data/smartbudget.db` |
| `SECRET_KEY` | Clave JWT | `"change-me"` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Caducidad JWT | `1440` (24h) |
| `LOW_BUDGET_THRESHOLD` | % restante para alertas de presupuesto | `0.25` |
| `ALERT_PERCENTAGE_VARIATION` | % para alerta de ocio | `0.3` |

Tras modificar `.env`, reinicia el servidor para que se apliquen los cambios.

### Migraciones y base de datos

No se usa Alembic por ahora. Las tablas se crean automÃ¡ticamente en el evento `startup` (`Base.metadata.create_all`). Para reiniciar, elimina `data/smartbudget.db`.

### EjecuciÃ³n (backend)

```powershell
cd Backend
uvicorn api.main:app --reload
# Disponible en http://127.0.0.1:8000 y documentaciÃ³n en /docs
```

### Resumen de endpoints

| MÃ©todo | Ruta | DescripciÃ³n | Auth |
|--------|------|-------------|------|
| POST | `/api/auth/register` | Crear usuario | âŒ |
| POST | `/api/auth/login` | Obtener tokens (access/refresh) | âŒ |
| GET  | `/api/auth/me` | Perfil del usuario autenticado | âœ… |
| POST | `/api/budgets/` | Crear/actualizar presupuesto mensual | âœ… |
| GET  | `/api/budgets/current` | Presupuesto del mes actual | âœ… |
| GET  | `/api/budgets/history` | Historial de presupuestos | âœ… |
| POST | `/api/expenses/` | Registrar gasto manual | âœ… |
| GET  | `/api/expenses` | Listar gastos (filtros por categorÃ­a) | âœ… |
| GET  | `/api/alerts` | Alertas (opcional incluir reconocidas) | âœ… |
| POST | `/api/alerts/{alert_id}/ack` | Marcar alerta como atendida | âœ… |
| POST | `/api/smartscore/recalculate` | Recalcular SmartScore | âœ… |
| GET  | `/api/smartscore/history` | Historial de snapshots | âœ… |
| POST | `/api/simulator/` | Simular escenario â€œÂ¿Y siâ€¦?â€ | âœ… |
| GET  | `/api/goals/` | Listar metas | âœ… |
| POST | `/api/goals/` | Crear meta | âœ… |
| POST | `/api/goals/{goal_id}/progress` | Actualizar progreso de meta | âœ… |
| GET  | `/api/goals/suggestions` | Sugerencias dinÃ¡micas | âœ… |

Todas las rutas autenticadas requieren header `Authorization: Bearer <access_token>`.

**Notas clave**:
- Los gastos asociados a un presupuesto recalculan automÃ¡ticamente el saldo, SmartScore y alertas.
- OCR devuelve descripciÃ³n, monto, fecha, categorÃ­a y texto normalizado.
- El simulador ofrece escenarios `reduce_expenses`, `increase_savings`, `custom`.

---

## Frontend

- Ubicado en `Frontend/` con siguientes carpetas:
  ```
  Frontend/
  â”œâ”€â”€ index.html                  # Landing pÃºblica
  â”œâ”€â”€ pages/
  â”‚   â”œâ”€â”€ login.html, register.html
  â”‚   â”œâ”€â”€ dashboard.html, budget.html, expenses.html
  â”‚   â”œâ”€â”€ smartscore.html, simulator.html, goals.html, profile.html
  â””â”€â”€ assets/
      â”œâ”€â”€ css/styles.css          # Paleta verde/blanco + utilidades
      â”œâ”€â”€ js/core.js              # Auth, fetch, nav, helpers
      â””â”€â”€ js/*.js                 # LÃ³gica especÃ­fica de cada pÃ¡gina
  ```

- **Servir el frontend** (cualquier servidor estÃ¡tico):
  ```powershell
  cd Frontend
  python -m http.server 9000
  ```
  Accede a `http://127.0.0.1:9000`. El `core.js` asume el backend en `http://127.0.0.1:8000/api`; ajusta `API_BASE_URL` si usas otra URL.

- **NavegaciÃ³n dinÃ¡mica**:
  - Sin sesiÃ³n: sÃ³lo *Inicio*, *Registrarse* e *Iniciar sesiÃ³n*.
  - Con sesiÃ³n: *Dashboard, Presupuesto, Gastos, SmartScore, Simulador, Metas, Perfil* y botÃ³n de *Cerrar sesiÃ³n*.

- **Autocompletado OCR**: Al procesar una boleta, la vista de gastos llena automÃ¡ticamente descripciÃ³n, monto, fecha y categorÃ­a detectadas (puedes editarlas antes de guardar).

---

## OCR y análisis de boletas

1. El **frontend web** y la **app móvil** suben la imagen/PDF al webhook de n8n configurado en `ocrWebhookUrl`.
2. La automatización se encarga de guardar el archivo donde prefieras, ejecutar OCR (Vision, Tesseract, servicios cloud, etc.) y devolver un JSON con los campos normalizados.
3. El frontend muestra el texto/raw payload devuelto, autocompleta los formularios y envía el gasto al backend usando el endpoint manual (`/api/expenses/`).
4. Si necesitas guardar archivos o texto crudo, puedes incluirlos en `extra_data` al confirmar el gasto.

**Consejos**:
- Mantén activo el workflow de n8n (toggle en la esquina superior derecha) para que responda sin pulsar “Execute”.
- Si actualizas la URL del webhook, cambia también `window.__SB_RUNTIME_CONFIG__.ocrWebhookUrl` (web) y `mobile/assets/config/runtime.json` (app).

---

## Flujos funcionales

1. **Onboarding**:
   - Landing â†’ Registro con ingresos opcionales â†’ Login.
2. **Mes nuevo**:
   - Definir presupuesto mensual (`/api/budgets/`).
   - Los gastos se asocian automÃ¡ticamente al presupuesto segÃºn fecha.
3. **Registro de gastos**:
   - Manual o OCR.
   - Actualiza saldo `spent/remaining`, SmartScore y alertas en el momento.
4. **SmartScore**:
   - `calculate_smartscore` evalÃºa ratio de gasto y penaliza categorÃ­as (ej. ocio > 25%).
   - Se registran snapshots histÃ³ricos.
   - Alertas automÃ¡ticas si el score cae a moderado/riesgo.
5. **Simulador**:
   - Escenarios predefinidos o personalizados (por categorÃ­a).
   - Devuelve el SmartScore proyectado y ajustes monetarios.
6. **Metas**:
   - Crea retos (nombre, monto, fecha).
   - Actualiza progreso con montos acumulados.
   - Recomienda nuevas metas (ahorra 15%, reduce transporte, etc.).

---

## Testing manual recomendado

1. **AutenticaciÃ³n**: Registro â†’ Login â†’ Verificar `Authorization` en consola del navegador.
2. **Presupuesto**: Crear presupuesto y comprobar que `data/smartbudget.db` registra el registro en tabla `budgets`.
3. **Gastos manuales**: Registrar 2-3 gastos en distintas categorÃ­as; observar saldo restante y alertas.
4. **Gastos OCR**: Subir cualquier boleta desde el formulario (web o app). Verifica que se llame al webhook de n8n, que el payload llene los campos y que luego puedas registrar el gasto manualmente.
5. **SmartScore**: Tras registrar gastos, forzar recÃ¡lculo desde la vista y revisar historial/alertas.
6. **Simulador**: Probar los escenarios `reduce_expenses` y el personalizado con categorÃ­a ocio.
7. **Metas**: Crear meta, actualizar progreso e inspeccionar sugerencias.
8. **Front-back cohesion**: Cerrar sesiÃ³n â†’ verificar que la navegaciÃ³n vuelva al modo pÃºblico.

---

## Notas y futuras mejoras

- AÃ±adir **migraciones Alembic** para entornos productivos.
- Implementar **refresh tokens** explÃ­citos y endpoint de revocaciÃ³n.
- Soportar **subida a S3/Blob** para boletas en despliegues en la nube.
- Agregar **tests automatizados** (PyTest) para servicios crÃ­ticos.
- OpciÃ³n de **filtrar gastos por rango de fechas** y exportar CSV.
- Integrar **grÃ¡ficos** en frontend (Chart.js) para presupuestos vs. gastos.

---

Â¡Listo! Con esta documentaciÃ³n puedes configurar el entorno, ejecutar backend y frontend, comprender la arquitectura y los endpoints clave, y extender SmartBudget+ segÃºn tus futuras necesidades.






