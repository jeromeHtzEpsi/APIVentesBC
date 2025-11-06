# Utiliser une image officielle Python 3.12
FROM python:3.12-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY pyproject.toml poetry.lock* /app/

# Installer Poetry
RUN pip install --no-cache-dir poetry

# Installer les dépendances via Poetry
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi

# Copier tout le code du projet
COPY . /app

# Exposer le port FastAPI
EXPOSE 8000

# Commande pour lancer FastAPI avec uvicorn
CMD ["uvicorn", "MachineLearningExt.Python.main:app", "--host", "0.0.0.0", "--port", "8000"]
