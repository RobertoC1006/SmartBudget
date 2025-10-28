# Simulador "¿Y si...?"
from core.smartscore_engine import calcular_smartscore

def simular_cambio(gastos: list, ingreso_mensual: float, reduccion_por_categoria: dict):

    gastos_simulados = []

    for g in gastos:
        categoria = g["descripcion"]
        monto = g["monto"]

        if categoria in reduccion_por_categoria:
            reduccion = reduccion_por_categoria[categoria]
            nuevo_monto = monto * (1 - reduccion / 100)
        else:
            nuevo_monto = monto

        gastos_simulados.append({"descripcion": categoria, "monto": nuevo_monto})

    # Calcula nuevo SmartScore con gastos simulados (mejoras recomendadas)
    resultado_original = calcular_smartscore(gastos, ingreso_mensual)
    resultado_simulado = calcular_smartscore(gastos_simulados, ingreso_mensual)

    diferencia = resultado_simulado["smartscore"] - resultado_original["smartscore"]

    print("\n=== RESULTADO DEL SIMULADOR ===")
    print(f"SmartScore original: {resultado_original['smartscore']}")
    print(f"SmartScore simulado: {resultado_simulado['smartscore']}")
    if diferencia >= 0:
        print(f"Mejora de {round(diferencia, 2)} puntos")
    else:
        print(f"Disminución de {abs(round(diferencia, 2))} puntos")

    return {
        "original": resultado_original,
        "simulado": resultado_simulado,
        "diferencia": round(diferencia, 2)
    }


# --- PRUEBA MANUAL ---
if __name__ == "__main__":
    gastos = [
        {"descripcion": "Comida", "monto": 500},
        {"descripcion": "Transporte", "monto": 200},
        {"descripcion": "Ocio", "monto": 300}
    ]

    ingreso_mensual = 2000

    reduccion = {"Ocio": 20}  # Simula reducir 20% en ocio

    simular_cambio(gastos, ingreso_mensual, reduccion)
