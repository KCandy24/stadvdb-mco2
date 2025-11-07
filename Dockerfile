FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    # curl to get uv directly
    libpq5 \
    libpq-dev \
    # libpq cuz psycog needs it
    gcc \
    # idfk why gcc is here
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# download uv directly

ENV PATH="/root/.local/bin:${PATH}"
# uv doesnt run so gotta set path too

COPY pyproject.toml uv.lock ./

RUN uv sync
# copy dependencies first to install it

COPY app ./app

ENV FLASK_APP=app
ENV FLASK_RUN_HOST=0.0.0.0

EXPOSE 5000

CMD ["uv", "run", "flask", "run", "--debug", "--host=0.0.0.0"]
