import os

from fastapi import FastAPI
from .database import Base, engine
from .routers import movies, persons, probe

app = FastAPI()

# Créer les tables si demandé explicitement (prototypage / sqlite)
if os.environ.get("DB_CREATE_TABLES", "false").lower() == "true":
    Base.metadata.create_all(bind=engine)

app.include_router(movies.router)
app.include_router(persons.router)
app.include_router(probe.router)
