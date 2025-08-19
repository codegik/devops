#!/bin/bash

set -e

echo "🛑 Stopping PGSync infrastructure..."

# Check if docker compose is available
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ docker compose is not available. Please update Docker to a newer version."
    exit 1
fi

# Stop and remove all containers
echo "📦 Stopping all services..."
docker compose down

# Remove volumes (optional - uncomment if you want to remove data)
# echo "🗑️  Removing volumes..."
# docker compose down -v

# Remove unused Docker resources
echo "🧹 Cleaning up unused Docker resources..."
docker system prune -f

echo ""
echo "✅ All services have been stopped and cleaned up!"
echo ""
echo "💡 Note: Data volumes are preserved. To remove all data, run:"
echo "   docker compose down -v"
