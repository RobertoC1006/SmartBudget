import pytesseract               # Librería OCR
from PIL import Image            # Para abrir imágenes fácilmente
import cv2                       # Para preprocesar imágenes (opcional)
import os
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
def extraer_texto(ruta_imagen: str) -> str:
    """
    Extrae texto desde una imagen de boleta o recibo.
    
    Parámetros:
        ruta_imagen (str): ruta completa del archivo de imagen (ejemplo: 'data/boleta1.jpg')
    
    Retorna:
        str: texto detectado dentro de la imagen
    """
    # 1️⃣ Abrir la imagen
    imagen = Image.open(ruta_imagen)

    # 2️⃣ (Opcional) Convertir a escala de grises y limpiar un poco con OpenCV
    img_cv = cv2.imread(ruta_imagen)
    gris = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
    _, umbral = cv2.threshold(gris, 150, 255, cv2.THRESH_BINARY)

    # 3️⃣ Usar pytesseract para reconocer el texto
    texto = pytesseract.image_to_string(umbral, lang='spa')  # 'spa' = idioma español

    return texto

# Bloque de prueba directa (solo se ejecuta si corres este archivo)
if __name__ == "__main__":
    ruta = "data/boleta_ejemplo.jpg"   # Cambia por tu imagen real
    if os.path.exists(ruta):
        resultado = extraer_texto(ruta)
        print("🧾 Texto detectado:\n", resultado)
    else:
        print("⚠️ No se encontró la imagen:", ruta)