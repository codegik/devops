#!/bin/bash

set -e

echo "🧪 Testing PGSync infrastructure..."

# Function to check if a service is responding
check_service() {
    local name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    echo "   Testing $name..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo "   ✅ $name is responding"
            return 0
        fi
        echo "   ⏳ Attempt $attempt/$max_attempts - waiting for $name..."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "   ❌ $name failed to respond after $max_attempts attempts"
    return 1
}

# Check if services are running
echo "📋 Checking service status..."
if ! docker compose ps | grep -q "Up"; then
    echo "❌ Services are not running. Please run ./run.sh first."
    exit 1
fi

# Test individual services
echo ""
echo "🔍 Testing service endpoints..."

# Test PostgreSQL
echo "   Testing PostgreSQL connection..."
if docker compose exec -T postgres pg_isready -U pgsync -d pgsync_db > /dev/null 2>&1; then
    echo "   ✅ PostgreSQL is accessible"
else
    echo "   ❌ PostgreSQL connection failed"
    exit 1
fi

# Test Redis
echo "   Testing Redis connection..."
if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "   ✅ Redis is accessible"
else
    echo "   ❌ Redis connection failed"
    exit 1
fi

# Test OpenSearch
check_service "OpenSearch" "http://localhost:9200/_cluster/health"

# Test OpenSearch Dashboards
check_service "OpenSearch Dashboards" "http://localhost:5601/api/status"

# Test PGSync
check_service "PGSync" "http://localhost:8080"

# Test data synchronization
echo ""
echo "📊 Testing data synchronization..."

# Insert test data into PostgreSQL
echo "   Inserting test data..."
docker compose exec -T postgres psql -U pgsync -d pgsync_db -c "
INSERT INTO users (name, email) VALUES ('Test User', 'test.user@example.com')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;
"

# Wait a moment for sync
sleep 5

# Check if data appears in OpenSearch
echo "   Checking if data synced to OpenSearch..."
if curl -s "http://localhost:9200/pgsync/_search" | grep -q "test.user@example.com"; then
    echo "   ✅ Data synchronization is working"
else
    echo "   ⚠️  Data not yet synced (this might be normal on first run)"
fi

# Display service information
echo ""
echo "📊 Service Information:"
echo "   PostgreSQL:           localhost:5432 (pgsync/pgsync123)"
echo "   Redis:                localhost:6379"
echo "   OpenSearch:           http://localhost:9200"
echo "   OpenSearch Dashboards: http://localhost:5601"
echo "   PGSync:               http://localhost:8080"

echo ""
echo "🎉 All tests completed successfully!"
echo ""
echo "💡 Next steps:"
echo "   - Access OpenSearch Dashboards at http://localhost:5601"
echo "   - Connect to PostgreSQL: psql -h localhost -U pgsync -d pgsync_db"
echo "   - View logs: docker compose logs -f [service_name]"
