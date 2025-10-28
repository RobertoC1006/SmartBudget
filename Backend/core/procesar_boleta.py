# =========================================================
# 🧩 procesar_boleta.py — Integración OCR + Limpiador (rutas robustas)
# =========================================================
from ocr import extraer_texto
from limpiador_datos import limpiar_texto
import os, json

# 0) Base absoluta del script: .../SmartBudget/Backend/core
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# 1) Subimos a Backend
BACKEND_DIR = os.path.dirname(SCRIPT_DIR)
# 2) Carpeta data real: .../SmartBudget/Backend/data
DATA_DIR = os.path.join(BACKEND_DIR, "data")

# (Opcional) Mostrar rutas para depurar una sola vez
print("📂 SCRIPT_DIR:", SCRIPT_DIR)
print("📂 BACKEND_DIR:", BACKEND_DIR)
print("📂 DATA_DIR:", DATA_DIR)

# Pide la imagen
nombre_imagen = input("🖼️ Ingresa el nombre de la imagen (ejemplo: boleta2.jpg): ").strip()
ruta = os.path.join(DATA_DIR, nombre_imagen)

# Verifica existencia
if not os.path.exists(ruta):
    print(f"⚠️ No se encontró la imagen en: {ruta}")
else:
    # 1) OCR
    texto = extraer_texto(ruta)
    print("\n🧾 Texto detectado por OCR:\n")
    print(texto)
    print("-" * 60)

    # 2) Limpieza
    resultado = limpiar_texto(texto)
    print("\n📊 Datos estructurados:\n")
    print(json.dumps(resultado, indent=4, ensure_ascii=False))
