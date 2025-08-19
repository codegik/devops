#!/bin/bash

set -e

echo "🚀 Starting PGSync infrastructure with Docker Compose..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker compose is available
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ docker compose is not available. Please update Docker to a newer version."
    exit 1
fi

# Create necessary directories
mkdir -p logs

# Start all services
echo "📦 Starting services..."
docker compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."

# Check PostgreSQL
echo "   Checking PostgreSQL..."
timeout=60
counter=0
while ! docker compose exec -T postgres pg_isready -U pgsync -d pgsync_db > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "❌ PostgreSQL failed to start within $timeout seconds"
        docker compose logs postgres
        exit 1
    fi
    counter=$((counter + 1))
    sleep 1
done
echo "   ✅ PostgreSQL is ready"

# Check Redis
echo "   Checking Redis..."
counter=0
while ! docker compose exec -T redis redis-cli ping > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "❌ Redis failed to start within $timeout seconds"
        docker compose logs redis
        exit 1
    fi
    counter=$((counter + 1))
    sleep 1
done
echo "   ✅ Redis is ready"

# Check OpenSearch
echo "   Checking OpenSearch..."
counter=0
while ! curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "❌ OpenSearch failed to start within $timeout seconds"
        docker compose logs opensearch
        exit 1
    fi
    counter=$((counter + 1))
    sleep 1
done
echo "   ✅ OpenSearch is ready"

# Check OpenSearch Dashboards
echo "   Checking OpenSearch Dashboards..."
counter=0
while ! curl -s http://localhost:5601/api/status > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "❌ OpenSearch Dashboards failed to start within $timeout seconds"
        docker compose logs opensearch-dashboards
        exit 1
    fi
    counter=$((counter + 1))
    sleep 1
done
echo "   ✅ OpenSearch Dashboards is ready"

# Check PGSync
echo "   Checking PGSync..."
counter=0
while ! curl -s http://localhost:8080 > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "❌ PGSync failed to start within $timeout seconds"
        docker compose logs pgsync
        exit 1
    fi
    counter=$((counter + 1))
    sleep 1
done
echo "   ✅ PGSync is ready"

echo ""
echo "🎉 All services are up and running!"
echo ""
echo "📊 Service URLs:"
echo "   PostgreSQL:          localhost:5432"
echo "   Redis:               localhost:6379"
echo "   OpenSearch:          http://localhost:9200"
echo "   OpenSearch Dashboards: http://localhost:5601"
echo "   PGSync:              http://localhost:8080"
echo ""
echo "🔗 Database Connection:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: pgsync_db"
echo "   Username: pgsync"
echo "   Password: pgsync123"
echo ""
echo "📝 To view logs:"
echo "   docker compose logs -f [service_name]"
echo ""
echo "🛑 To stop all services:"
echo "   ./destroy.sh"
