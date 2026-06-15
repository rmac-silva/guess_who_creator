#!/bin/bash
set -e

PROJECT_NAME="Guess-Who-Creator"
CONTAINER_NAME="guesswho_backend"
IMAGE_NAME="guesswho_backend:latest"
VOLUME_NAME="guesswho_db_volume"

echo "🚀 Pulling latest code for $PROJECT_NAME..."
git pull origin main

echo "🛑 Stopping running container (if any)..."
docker stop $CONTAINER_NAME 2>/dev/null || true

echo "🗑️ Removing old container..."
docker rm $CONTAINER_NAME 2>/dev/null || true

echo "🛠️ Building new Docker image..."
# Builds using the Dockerfile in the root, which copies the project structure
docker build -t $IMAGE_NAME .

echo "📦 Ensuring persistent database volume exists..."
docker volume inspect $VOLUME_NAME >/dev/null 2>&1 || docker volume create $VOLUME_NAME

echo "🏃 Starting $PROJECT_NAME container..."
docker run -d \
  --name $CONTAINER_NAME \
  -v $VOLUME_NAME:/app/data \
  -e RUNNING_ON_CONTAINER=true \
  -e DB_PATH=/app/data/guesswho.db \
  -e CORS_ORIGINS=https://guesswho.blazy.uk \
  -p 8000:8000 \
  --restart unless-stopped \
  $IMAGE_NAME

echo "✅ $PROJECT_NAME deployment complete!"