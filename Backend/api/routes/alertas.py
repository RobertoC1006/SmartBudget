from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.api.dependencies import get_current_user
from Backend.api.schemas import alert as alert_schema
from Backend.core import alertas as alerts_service
from Backend.db import models
from Backend.db.session import get_db


# Esta línea de código crea una instancia de la clase `APIRouter` desde el marco FastAPI. el
# El parámetro `prefix="/alerts"` establece la ruta base para que todas las rutas definidas dentro de este enrutador sean
# `/alertas`. Esto significa que se accederá a todos los puntos finales definidos en este enrutador bajo el
# Ruta `/alertas`.
router = APIRouter(prefix="/alerts", tags=["Alertas"])

""" 
Esta función enumera alertas para el usuario actual, con una opción para incluir alertas reconocidas. 

:param db: El parámetro `db` es de tipo `Session` y se utiliza para interactuar con la base de datos. es 
obtenido usando la dependencia `get_db` 
:tipo db: sesión 
:param current_user: El parámetro `current_user` en la función `list_alerts` es de tipo 
`models.User` y se obtiene llamando a la dependencia `get_current_user`. Este parámetro 
representa al usuario que está actualmente autenticado y que realiza la solicitud para enumerar alertas. se usa 
para filtrar las alertas según 
: escriba usuario_actual: modelos.Usuario 
:param include_acknowledged: El parámetro `include_acknowledged` es un indicador booleano que determina 
si incluir o no alertas reconocidas en la lista de alertas devueltas por `list_alerts` 
punto final. Si `include_acknowledged` se establece en `True`, las alertas reconocidas se incluirán en el 
lista. Si es así, el valor predeterminado es Falso 
:tipo include_acknowledged: bool (opcional) 
:return: Se devuelve una lista de alertas. Cada alerta está representada por una instancia del 
Esquema `AlertRead` definido en el módulo `alert_schema`.
"""
@router.get("/", response_model=list[alert_schema.AlertRead])

def list_alerts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
    include_acknowledged: bool = False,
):
    alerts = alerts_service.list_alerts(db, current_user.id, include_acknowledged)
    return list(alerts)


@router.post("/{alert_id}/ack", response_model=alert_schema.AlertRead)
def acknowledge_alert(
    alert_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    alert = (
        db.query(models.Alert)
        .filter(models.Alert.id == alert_id, models.Alert.user_id == current_user.id)
        .first()
    )
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alerta no encontrada.")
    updated = alerts_service.acknowledge_alert(db, alert)
    return updated

