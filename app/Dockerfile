FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --requirement requirements.txt

COPY main.py .

# Matches runAsUser / runAsGroup in the Kubernetes deployment.
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid 10001 --no-create-home app
USER 10001:10001

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
