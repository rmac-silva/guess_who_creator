# Stage 1: Build & Install dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# CHANGE THIS LINE: Point Docker to the src folder version
COPY src/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Final minimal runtime execution image
FROM python:3.11-slim AS runner

WORKDIR /app

# Copy installed dependencies from builder stage
COPY --from=builder /root/.local /root/.local
COPY . .

# FIX 1: Corrected the PATH environment syntax to look at the python bin folder
ENV PATH="/root/.local/bin:${PATH}"

ENV RUNNING_ON_CONTAINER=true
ENV DB_PATH=/app/data/guesswho.db
ENV CORS_ORIGINS=https://guesswho.blazy.uk

RUN mkdir -p /app/data

EXPOSE 8000

# FIX 2: Updated the module path to "src.main:app" since your code is in the src directory,
# and reverted port back to 8000 to match your deploy script mapping!
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]