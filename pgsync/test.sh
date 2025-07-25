#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_status $YELLOW "Running test: $test_name"

    if eval "$test_command"; then
        print_status $GREEN "✅ PASSED: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_status $RED "❌ FAILED: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_attempts=30
    local attempt=1

    print_status $BLUE "Waiting for $service_name to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if eval "$check_command" &>/dev/null; then
            print_status $GREEN "$service_name is ready!"
            return 0
        fi

        echo -n "."
        sleep 5
        attempt=$((attempt + 1))
    done

    print_status $RED "$service_name failed to become ready after $((max_attempts * 5)) seconds"
    return 1
}

# Test if PostgreSQL is accessible
test_postgresql_connection() {
    PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -c "SELECT 1;" &>/dev/null
}

# Test if OpenSearch is accessible
test_opensearch_connection() {
    curl -k -s "https://localhost:9200/_cluster/health" | grep -q "yellow\|green"
}

# Test if PGSync is running
test_pgsync_status() {
    kubectl get pods -n pgsync | grep pgsync | grep -q Running
}

# Test if PGSync API is accessible
test_pgsync_api() {
    curl -s "http://localhost:8080/status" &>/dev/null || curl -s "http://localhost:8080" &>/dev/null
}

# Insert test data into PostgreSQL
insert_test_data() {
    local test_email="test-$(date +%s)@example.com"
    local test_name="Test User $(date +%s)"

    PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -c "
        INSERT INTO users (name, email) VALUES ('$test_name', '$test_email');
    " &>/dev/null

    echo "$test_email"
}

# Check if data exists in OpenSearch
check_data_in_opensearch() {
    local test_email=$1
    local max_attempts=20
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local result=$(curl -k -s "https://localhost:9200/pgsync/_search" -H "Content-Type: application/json" -d "{
            \"query\": {
                \"match\": {
                    \"email\": \"$test_email\"
                }
            }
        }" | grep -c "$test_email")

        if [ "$result" -gt 0 ]; then
            return 0
        fi

        sleep 3
        attempt=$((attempt + 1))
    done

    return 1
}

# Test data synchronization
test_data_sync() {
    print_status $BLUE "Testing data synchronization..."

    # Insert test data
    local test_email=$(insert_test_data)
    if [ $? -ne 0 ]; then
        return 1
    fi

    print_status $YELLOW "Inserted test data with email: $test_email"
    print_status $YELLOW "Waiting for data to sync to OpenSearch..."

    # Check if data appears in OpenSearch
    if check_data_in_opensearch "$test_email"; then
        print_status $GREEN "Data successfully synchronized!"
        return 0
    else
        print_status $RED "Data synchronization failed!"
        return 1
    fi
}

# Test PostgreSQL table structure
test_postgresql_schema() {
    PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -c "
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name IN ('users', 'products', 'categories');
    " | grep -q users && grep -q products && grep -q categories
}

# Test OpenSearch index
test_opensearch_index() {
    curl -k -s "https://localhost:9200/_cat/indices" | grep -q pgsync
}

# Test if sample data exists
test_sample_data() {
    local user_count=$(PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -t -c "SELECT COUNT(*) FROM users;")
    [ "$user_count" -gt 0 ] 2>/dev/null
}

# Main test execution
print_status $BLUE "🚀 Starting PGSync Infrastructure Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for services to be ready
wait_for_service "PostgreSQL" "test_postgresql_connection"
wait_for_service "OpenSearch" "test_opensearch_connection"
wait_for_service "PGSync" "test_pgsync_status"

echo ""
print_status $BLUE "🔍 Running Infrastructure Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Basic connectivity tests
run_test "PostgreSQL Connection" "test_postgresql_connection"
run_test "OpenSearch Connection" "test_opensearch_connection"
run_test "PGSync Pod Status" "test_pgsync_status"
run_test "PGSync API Access" "test_pgsync_api"

# Schema and data tests
run_test "PostgreSQL Schema" "test_postgresql_schema"
run_test "OpenSearch Index" "test_opensearch_index"
run_test "Sample Data Exists" "test_sample_data"

echo ""
print_status $BLUE "🔄 Testing Data Synchronization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Data synchronization test
run_test "Real-time Data Sync" "test_data_sync"

echo ""
print_status $BLUE "📊 Additional Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show current data counts
print_status $YELLOW "Data Statistics:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# PostgreSQL data counts
if test_postgresql_connection; then
    USER_COUNT=$(PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs)
    PRODUCT_COUNT=$(PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -t -c "SELECT COUNT(*) FROM products;" 2>/dev/null | xargs)
    CATEGORY_COUNT=$(PGPASSWORD=pgsync123 psql -h localhost -p 5432 -U pgsync -d pgsync_db -t -c "SELECT COUNT(*) FROM categories;" 2>/dev/null | xargs)

    print_status $BLUE "PostgreSQL Records:"
    echo "  Users: $USER_COUNT"
    echo "  Products: $PRODUCT_COUNT"
    echo "  Categories: $CATEGORY_COUNT"
fi

# OpenSearch data counts
if test_opensearch_connection; then
    OPENSEARCH_COUNT=$(curl -k -s "https://localhost:9200/pgsync/_count" | grep -o '"count":[0-9]*' | cut -d: -f2 2>/dev/null)
    print_status $BLUE "OpenSearch Records: ${OPENSEARCH_COUNT:-0}"
fi

# Show PGSync logs (last 10 lines)
print_status $YELLOW "Recent PGSync Logs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl logs -n pgsync deployment/pgsync --tail=10 2>/dev/null || echo "Could not retrieve PGSync logs"

echo ""
echo ""
print_status $BLUE "📝 Test Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_status $YELLOW "Total Tests Executed: $TOTAL_TESTS"
print_status $GREEN "Tests Passed: $PASSED_TESTS"
print_status $RED "Tests Failed: $FAILED_TESTS"

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    print_status $BLUE "Success Rate: ${SUCCESS_RATE}%"

    if [ $SUCCESS_RATE -eq 100 ]; then
        print_status $GREEN "🎉 All tests passed! PGSync is working correctly!"
    elif [ $SUCCESS_RATE -ge 80 ]; then
        print_status $YELLOW "⚠️  Most tests passed, but some issues detected."
    else
        print_status $RED "🚨 Multiple test failures detected. Please check your setup."
    fi
else
    print_status $RED "No tests were executed."
fi

echo ""
print_status $BLUE "🔗 Service URLs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PostgreSQL: postgresql://pgsync:pgsync123@localhost:5432/pgsync_db"
echo "OpenSearch: https://localhost:9200"
echo "OpenSearch Dashboard: http://localhost:5601"
echo "PGSync API: http://localhost:8080"

# Exit with error code if any tests failed
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
else
    exit 0
fi
