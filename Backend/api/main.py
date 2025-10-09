# Endpoints del servidor

from fastapi import FastAPI

app = FastAPI(title="SmartBudget+ API")

@app.get("/")
def home():
    return {"mensaje": "Bienvenido a SmartBudget+"}
