from colorama import Fore, Style

def calcular_smartscore(gastos: list, ingreso_mensual: float):
    """
    Calcula el puntaje financiero del usuario (SmartScore) basado en sus gastos e ingresos.
    Devuelve también el color asociado al estado financiero.
    """
    total_gastos = sum(g["monto"] for g in gastos)
    porcentaje_gasto = (total_gastos / ingreso_mensual) * 100 if ingreso_mensual > 0 else 100

    # Lógica de puntuación: mientras menos porcentaje de gasto, mejor puntaje
    if porcentaje_gasto <= 50:
        score = 90 + (50 - porcentaje_gasto) * 0.2
        estado = "Excelente"
        color = Fore.GREEN
    elif porcentaje_gasto <= 70:
        score = 75
        estado = "Bueno"
        color = Fore.YELLOW
    elif porcentaje_gasto <= 90:
        score = 60
        estado = "Regular"
        color = Fore.LIGHTRED_EX
    else:
        score = 40
        estado = "Crítico"
        color = Fore.RED

    resultado = {
        "total_gastos": total_gastos,
        "porcentaje_gasto": round(porcentaje_gasto, 2),
        "smartscore": round(score, 2),
        "estado": estado,
        "color": color,
        "recomendacion": generar_recomendacion(estado)
    }

    # Muestra formateada en consola (solo para pruebas)
    print(Style.BRIGHT + f"\n=== RESULTADO SMARTSCORE ===")
    print(f"Total de gastos: S/ {total_gastos}")
    print(f"Porcentaje de gasto: {round(porcentaje_gasto, 2)}%")
    print(f"SmartScore: {round(score, 2)}")
    print(color + f"Estado: {estado}" + Style.RESET_ALL)
    print(f"Recomendación: {resultado['recomendacion']}\n")

    return resultado


def generar_recomendacion(estado: str):
    """
    Devuelve recomendaciones según el estado financiero del usuario.
    """
    mensajes = {
        "Excelente": "Mantén tu disciplina de ahorro, podrías comenzar a invertir.",
        "Bueno": "Buen manejo, pero podrías reducir pequeños gastos innecesarios.",
        "Regular": "Considera revisar tus gastos fijos y buscar mejores precios.",
        "Crítico": "Necesitas ajustar tu presupuesto urgentemente y priorizar tus necesidades."
    }
    return mensajes.get(estado, "Sin recomendaciones.")
