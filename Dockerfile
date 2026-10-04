FROM python:3.12-slim-bookworm

WORKDIR /app

ARG GIT_SHA=local
ENV GIT_SHA=$GIT_SHA

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8000

CMD ["python", "app.py"]