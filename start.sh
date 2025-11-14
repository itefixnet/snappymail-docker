#!/bin/bash

# SnappyMail Docker Startup Script
# This script helps you get SnappyMail up and running quickly

set -e

echo "🚀 Starting SnappyMail Docker Setup..."
echo "=================================="

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Configuration variables
CONTAINER_NAME="snappymail"
IMAGE_NAME="snappymail"
PORT="8080"
DATA_VOLUME="snappymail_data"

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "📝 Loading configuration from .env file..."
    export $(grep -v '^#' .env | xargs)
    # Use env vars if they exist
    CONTAINER_NAME="${CONTAINER_NAME:-snappymail}"
    PORT="${SNAPPYMAIL_PORT:-8080}"
    DATA_VOLUME="${DATA_VOLUME:-snappymail_data}"
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "� Stopping and removing existing container..."
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
fi

# Build the image
echo "🏗️  Building SnappyMail Docker image..."
docker build -t ${IMAGE_NAME} .

# Start the container
echo "🚀 Starting SnappyMail container..."
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${PORT}:80 \
    -v ${DATA_VOLUME}:/var/www/html/data \
    --restart unless-stopped \
    ${IMAGE_NAME}

# Wait a moment for the container to start
echo "⏳ Waiting for SnappyMail to start..."
sleep 10

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ SnappyMail is now running!"
    echo ""
    echo "📋 Quick Info:"
    echo "   🌐 Web Interface: http://localhost:${PORT}"
    echo "   🔧 Admin Panel: http://localhost:${PORT}/?admin"
    echo ""
    echo "🔐 Getting Admin Password:"
    echo "   Run: docker exec ${CONTAINER_NAME} cat /var/www/html/data/_data_/_default_/admin_password.txt"
    echo ""
    echo "📚 Need help? Check the README.md file"
    echo ""
    
    # Try to get admin password
    echo "🔑 Admin Password (if available):"
    if docker exec ${CONTAINER_NAME} test -f /var/www/html/data/_data_/_default_/admin_password.txt 2>/dev/null; then
        ADMIN_PASS=$(docker exec ${CONTAINER_NAME} cat /var/www/html/data/_data_/_default_/admin_password.txt 2>/dev/null | tr -d '\r\n' || echo "Not yet generated")
        echo "   Username: admin"
        echo "   Password: $ADMIN_PASS"
    else
        echo "   Password file not yet created. Visit http://localhost:${PORT}/?admin to generate it."
    fi
    
else
    echo "❌ Something went wrong. Check the logs:"
    echo "   docker logs ${CONTAINER_NAME}"
    exit 1
fi

echo ""
echo "🎉 Setup complete! Enjoy using SnappyMail!"