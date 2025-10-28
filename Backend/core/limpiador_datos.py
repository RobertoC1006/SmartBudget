import re
import json

def limpiar_texto(texto_raw: str) -> dict:
    """
    Limpia y estructura el texto crudo obtenido del OCR.
    Devuelve un diccionario con descripción, monto, fecha y categoría.
    """

    # 1️⃣ Normalizar texto
    texto = texto_raw.lower()
    texto = re.sub(r"[^a-z0-9áéíóúüñ\s\.,:/$-]", " ", texto)
    texto = re.sub(r"\s+", " ", texto).strip()

    # 2️⃣ Fecha (formato dd-mm-yyyy o dd/mm/yyyy)
    fecha_match = re.search(r"\b(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b", texto)
    fecha = fecha_match.group(1) if fecha_match else "desconocida"

    # 3️⃣ Monto (último “total” que aparezca)
    total_matches = re.findall(r"total(?:\s*[a-z]*\s*[:$]?\s*)([\d\.,-]+)", texto)
    if total_matches:
        monto = total_matches[-1]
    else:
        # fallback: último número grande
        numeros = re.findall(r"\d{3,6}", texto)
        monto = numeros[-1] if numeros else "0"

    # Limpieza del monto
    monto = monto.replace(".", "").replace(",", "").replace("-", "").strip()

    # 4️⃣ Clasificación simplificada
    # Palabras clave principales por grupo (sin listas largas)
    grupos = {
        "restaurante": ["restaurante", "café", "comida", "menu", "bar"],
        "supermercado": ["super", "mercado"],
        "ropa": ["ropa", "fashion", "vestido", "polera", "tienda"],
        "transporte": ["taxi", "bus", "uber", "gasolina"],
        "ocio": ["cine", "netflix", "parque"],
        "servicios": ["agua", "luz", "internet", "telefono"],
        "salud": ["farmacia", "clinica", "hospital"],
        "educacion": ["universidad", "colegio", "libro"]
    }

    categoria_detectada = "general"
    for cat, palabras in grupos.items():
        if any(p in texto for p in palabras):
            categoria_detectada = cat
            break

    # 5️⃣ Descripción
    descripcion = f"gasto en {categoria_detectada}"

    return {
        "descripcion": descripcion,
        "monto": monto,
        "fecha": fecha,
        "categoria": categoria_detectada
    }
