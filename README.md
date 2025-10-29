# SmartBudget+

Gestor de ahorros con backend en FastAPI y frontend estático (HTML + Bootstrap). Permite registrar presupuestos mensuales, cargar gastos (manuales u OCR), calcular el SmartScore financiero, simular escenarios “¿Y si…?” y gestionar metas de ahorro con alertas inteligentes.

---

## Tabla de contenidos

1. [Arquitectura general](#arquitectura-general)
2. [Requisitos previos](#requisitos-previos)
3. [Preparar el entorno](#preparar-el-entorno)
4. [Backend (FastAPI)](#backend-fastapi)
   - [Árbol de directorios](#árbol-de-directorios-backend)
   - [Variables de entorno](#variables-de-entorno)
   - [Migraciones y base de datos](#migraciones-y-base-de-datos)
   - [Ejecución](#ejecución-backend)
   - [Resumen de endpoints](#resumen-de-endpoints)
5. [Frontend](#frontend)
6. [OCR y análisis de boletas](#ocr-y-análisis-de-boletas)
7. [Flujos funcionales](#flujos-funcionales)
8. [Testing manual recomendado](#testing-manual-recomendado)
9. [Notas y futuras mejoras](#notas-y-futuras-mejoras)

---

## Arquitectura general

- **Backend**: FastAPI + SQLAlchemy 2 + Pydantic v2. Define modelos ORM para usuarios, presupuestos, gastos, alertas, metas y snapshots de SmartScore. Incluye servicios para:
  - Autenticación con JWT (`passlib[bcrypt]` y `python-jose`).
  - Gestión de presupuestos y gastos (manuales + OCR).
  - Calculo del SmartScore y generación de alertas.
  - Metas inteligentes y simulaciones de escenarios financieros.
  - OCR mediante `pytesseract` + `Pillow` (opcional `pdf2image`).
- **Base de datos**: SQLite por defecto (`data/smartbudget.db`), fácilmente configurable vía `DATABASE_URL`.
- **Frontend**: HTML estático + Bootstrap 5 + JavaScript nativo. Las vistas se sirven desde `Frontend/` y consumen la API vía `fetch`:
  - Páginas independientes para login, registro, panel, presupuesto, gastos, smartscore, simulador, metas y perfil.
  - Navegación dinámica según estado de sesión.
- **OCR**: Transformación de imagen/PDF a texto con Tesseract, normalización de datos y autocompletado en el frontend.

---

## Requisitos previos

1. **Python 3.11+** (se probó con 3.13).
2. **Tesseract OCR 5.5+** (para la carga de boletas):
   - Instala desde [UB Mannheim build](https://github.com/UB-Mannheim/tesseract/wiki).
   - Asegúrate de que `tesseract.exe` esté en el PATH o indica la ruta en `.env`.
3. (Opcional) **Poppler/Ghostscript** si procesarás PDFs con `pdf2image`.
4. Node no es necesario; el frontend es estático.

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

Para comprobar que Tesseract está accesible:

```powershell
tesseract --version            # desde una consola normal
# y luego dentro del venv:
.\.venv\Scripts\python -c "import pytesseract; print(pytesseract.get_tesseract_version())"
```

---

## Backend (FastAPI)

### Árbol de directorios (Backend/)

```
Backend/
├── api/
│   ├── main.py                # create_app() y registro de routers
│   ├── dependencies.py
│   ├── routes/
│   │   ├── auth.py
│   │   ├── budgets.py
│   │   ├── expenses.py
│   │   ├── smartscore.py
│   │   ├── simulator.py
│   │   ├── alerts.py
│   │   └── goals.py
│   └── schemas/               # Pydantic models para requests/responses
├── core/
│   ├── config.py              # Settings centralizados (pydantic-settings)
│   ├── security.py            # Hashing y JWT helpers
│   ├── auth.py                # Servicios de usuarios
│   ├── budgets.py, expenses.py, alerts.py, goals.py
│   ├── simulator.py, smartscore.py
│   ├── limpiador_datos.py     # Normalización texto OCR
│   ├── ocr.py                 # Integración Tesseract
│   └── storage.py, enums.py, etc.
├── db/
│   ├── session.py             # Engine + SessionLocal
│   ├── base.py                # Declarative base
│   └── models.py              # ORM modelo relacional
└── requirements.txt
```

### Variables de entorno

Usa `Backend/.env` (ya creado) o variables del entorno del sistema. Principales:

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `DATABASE_URL` | Cadena SQLAlchemy | `sqlite:///./data/smartbudget.db` |
| `SECRET_KEY` | Clave JWT | `"change-me"` |
| `TESSERACT_CMD` | Ruta absoluta al ejecutable de Tesseract | `None` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Caducidad JWT | `1440` (24h) |
| `LOW_BUDGET_THRESHOLD` | % restante para alertas de presupuesto | `0.25` |
| `ALERT_PERCENTAGE_VARIATION` | % para alerta de ocio | `0.3` |
| `OCR_LANGUAGE` | Idioma para Tesseract | `spa` |

Tras modificar `.env`, reinicia el servidor para que se apliquen los cambios.

### Migraciones y base de datos

No se usa Alembic por ahora. Las tablas se crean automáticamente en el evento `startup` (`Base.metadata.create_all`). Para reiniciar, elimina `data/smartbudget.db`.

### Ejecución (backend)

```powershell
cd Backend
uvicorn api.main:app --reload
# Disponible en http://127.0.0.1:8000 y documentación en /docs
```

### Resumen de endpoints

| Método | Ruta | Descripción | Auth |
|--------|------|-------------|------|
| POST | `/api/auth/register` | Crear usuario | ❌ |
| POST | `/api/auth/login` | Obtener tokens (access/refresh) | ❌ |
| GET  | `/api/auth/me` | Perfil del usuario autenticado | ✅ |
| POST | `/api/budgets/` | Crear/actualizar presupuesto mensual | ✅ |
| GET  | `/api/budgets/current` | Presupuesto del mes actual | ✅ |
| GET  | `/api/budgets/history` | Historial de presupuestos | ✅ |
| POST | `/api/expenses/` | Registrar gasto manual | ✅ |
| GET  | `/api/expenses` | Listar gastos (filtros por categoría) | ✅ |
| POST | `/api/expenses/upload` | Subir boleta (OCR + registro) | ✅ |
| GET  | `/api/alerts` | Alertas (opcional incluir reconocidas) | ✅ |
| POST | `/api/alerts/{alert_id}/ack` | Marcar alerta como atendida | ✅ |
| POST | `/api/smartscore/recalculate` | Recalcular SmartScore | ✅ |
| GET  | `/api/smartscore/history` | Historial de snapshots | ✅ |
| POST | `/api/simulator/` | Simular escenario “¿Y si…?” | ✅ |
| GET  | `/api/goals/` | Listar metas | ✅ |
| POST | `/api/goals/` | Crear meta | ✅ |
| POST | `/api/goals/{goal_id}/progress` | Actualizar progreso de meta | ✅ |
| GET  | `/api/goals/suggestions` | Sugerencias dinámicas | ✅ |

Todas las rutas autenticadas requieren header `Authorization: Bearer <access_token>`.

**Notas clave**:
- Los gastos asociados a un presupuesto recalculan automáticamente el saldo, SmartScore y alertas.
- OCR devuelve descripción, monto, fecha, categoría y texto normalizado.
- El simulador ofrece escenarios `reduce_expenses`, `increase_savings`, `custom`.

---

## Frontend

- Ubicado en `Frontend/` con siguientes carpetas:
  ```
  Frontend/
  ├── index.html                  # Landing pública
  ├── pages/
  │   ├── login.html, register.html
  │   ├── dashboard.html, budget.html, expenses.html
  │   ├── smartscore.html, simulator.html, goals.html, profile.html
  └── assets/
      ├── css/styles.css          # Paleta verde/blanco + utilidades
      ├── js/core.js              # Auth, fetch, nav, helpers
      └── js/*.js                 # Lógica específica de cada página
  ```

- **Servir el frontend** (cualquier servidor estático):
  ```powershell
  cd Frontend
  python -m http.server 9000
  ```
  Accede a `http://127.0.0.1:9000`. El `core.js` asume el backend en `http://127.0.0.1:8000/api`; ajusta `API_BASE_URL` si usas otra URL.

- **Navegación dinámica**:
  - Sin sesión: sólo *Inicio*, *Registrarse* e *Iniciar sesión*.
  - Con sesión: *Dashboard, Presupuesto, Gastos, SmartScore, Simulador, Metas, Perfil* y botón de *Cerrar sesión*.

- **Autocompletado OCR**: Al procesar una boleta, la vista de gastos llena automáticamente descripción, monto, fecha y categoría detectadas (puedes editarlas antes de guardar).

---

## OCR y análisis de boletas

1. Frontend envía la imagen/PDF a `/api/expenses/upload`.
2. Backend guarda la boleta en `storage/receipts/`, ejecuta Tesseract (`ocr.py`) y normaliza texto (`limpiador_datos.py`).
3. Se registra el gasto con fuente `ocr`, guardando el texto completo y la confianza.
4. Frontend muestra el texto normalizado e inicializa el formulario manual con los datos sugeridos.

**Requisitos**:
- Tesseract accesible (ver [Requisitos previos](#requisitos-previos)).
- Para PDF, instala además `poppler` o `Ghostscript` según tu SO.

---

## Flujos funcionales

1. **Onboarding**:
   - Landing → Registro con ingresos opcionales → Login.
2. **Mes nuevo**:
   - Definir presupuesto mensual (`/api/budgets/`).
   - Los gastos se asocian automáticamente al presupuesto según fecha.
3. **Registro de gastos**:
   - Manual o OCR.
   - Actualiza saldo `spent/remaining`, SmartScore y alertas en el momento.
4. **SmartScore**:
   - `calculate_smartscore` evalúa ratio de gasto y penaliza categorías (ej. ocio > 25%).
   - Se registran snapshots históricos.
   - Alertas automáticas si el score cae a moderado/riesgo.
5. **Simulador**:
   - Escenarios predefinidos o personalizados (por categoría).
   - Devuelve el SmartScore proyectado y ajustes monetarios.
6. **Metas**:
   - Crea retos (nombre, monto, fecha).
   - Actualiza progreso con montos acumulados.
   - Recomienda nuevas metas (ahorra 15%, reduce transporte, etc.).

---

## Testing manual recomendado

1. **Autenticación**: Registro → Login → Verificar `Authorization` en consola del navegador.
2. **Presupuesto**: Crear presupuesto y comprobar que `data/smartbudget.db` registra el registro en tabla `budgets`.
3. **Gastos manuales**: Registrar 2-3 gastos en distintas categorías; observar saldo restante y alertas.
4. **Gastos OCR**: Subir `data/boleta_ejemplo.jpg`. Confirmar que se autocompletan campos y se genera gasto con `source=ocr`.
5. **SmartScore**: Tras registrar gastos, forzar recálculo desde la vista y revisar historial/alertas.
6. **Simulador**: Probar los escenarios `reduce_expenses` y el personalizado con categoría ocio.
7. **Metas**: Crear meta, actualizar progreso e inspeccionar sugerencias.
8. **Front-back cohesion**: Cerrar sesión → verificar que la navegación vuelva al modo público.

---

## Notas y futuras mejoras

- Añadir **migraciones Alembic** para entornos productivos.
- Implementar **refresh tokens** explícitos y endpoint de revocación.
- Soportar **subida a S3/Blob** para boletas en despliegues en la nube.
- Agregar **tests automatizados** (PyTest) para servicios críticos.
- Opción de **filtrar gastos por rango de fechas** y exportar CSV.
- Integrar **gráficos** en frontend (Chart.js) para presupuestos vs. gastos.

---

¡Listo! Con esta documentación puedes configurar el entorno, ejecutar backend y frontend, comprender la arquitectura y los endpoints clave, y extender SmartBudget+ según tus futuras necesidades.

