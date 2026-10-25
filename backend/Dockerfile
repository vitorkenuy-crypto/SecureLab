FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Dependências primeiro: o Docker reaproveita esta camada enquanto o requirements.txt não mudar.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# A API não precisa de privilégios de administrador dentro do container.
RUN useradd --create-home --uid 1000 app && chown -R app:app /app
USER app

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
