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

# Function to track test results
track_test() {
    local test_passed=$1
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$test_passed" = "true" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

print_status $BLUE "🧪 Testing infrastructure after tofu apply..."
echo ""

# Test 1: Check if Kind cluster is running
print_status $YELLOW "1. Checking Kind cluster status..."
if kubectl cluster-info &> /dev/null; then
    print_status $GREEN "✅ Kind cluster is running"
    track_test true
else
    print_status $RED "❌ Kind cluster is not accessible"
    track_test false
    exit 1
fi

# Test 2: Check if all nodes are ready
print_status $YELLOW "2. Checking node status..."
NODE_STATUS=$(kubectl get nodes --no-headers | awk '{print $2}' | grep -v Ready | wc -l)
if [ $NODE_STATUS -eq 0 ]; then
    print_status $GREEN "✅ All nodes are ready"
    kubectl get nodes
    track_test true
else
    print_status $RED "❌ Some nodes are not ready"
    kubectl get nodes
    track_test false
fi

# Test 3: Check namespaces
print_status $YELLOW "3. Checking required namespaces..."
NAMESPACES=("iac" "app")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace $ns &> /dev/null; then
        print_status $GREEN "✅ Namespace '$ns' exists"
        track_test true
    else
        print_status $RED "❌ Namespace '$ns' not found"
        track_test false
    fi
done

# Test 4: Check Helm releases
print_status $YELLOW "4. Checking Helm releases..."
RELEASES=("prometheus" "grafana" "docker-registry" "jenkins")
for release in "${RELEASES[@]}"; do
    STATUS=$(helm status $release -n iac --output json 2>/dev/null | jq -r '.info.status' 2>/dev/null)
    if [ "$STATUS" = "deployed" ]; then
        print_status $GREEN "✅ Helm release '$release' is deployed"
        track_test true
    else
        print_status $RED "❌ Helm release '$release' is not deployed properly (status: $STATUS)"
        track_test false
    fi
done

# Test 5: Check pod status
print_status $YELLOW "5. Checking pod status in iac namespace..."
PENDING_PODS=$(kubectl get pods -n iac --no-headers | grep -v Running | grep -v Completed | wc -l)
if [ $PENDING_PODS -eq 0 ]; then
    print_status $GREEN "✅ All pods in iac namespace are running"
    track_test true
else
    print_status $RED "❌ Some pods are not running in iac namespace:"
    kubectl get pods -n iac | grep -v Running | grep -v Completed
    track_test false
fi

# Test 6: Check services and NodePorts
print_status $YELLOW "6. Checking services and NodePorts..."
SERVICES=(
    "prometheus-server:30300"
    "grafana:30400"
    "docker-registry:30500"
    "jenkins:30600"
)

for service_port in "${SERVICES[@]}"; do
    SERVICE=$(echo $service_port | cut -d: -f1)
    PORT=$(echo $service_port | cut -d: -f2)

    if kubectl get svc $SERVICE -n iac &> /dev/null; then
        NODEPORT=$(kubectl get svc $SERVICE -n iac -o jsonpath='{.spec.ports[0].nodePort}')
        if [ "$NODEPORT" = "$PORT" ]; then
            print_status $GREEN "✅ Service '$SERVICE' is accessible on NodePort $PORT"
            track_test true
        else
            print_status $RED "❌ Service '$SERVICE' NodePort mismatch (expected: $PORT, actual: $NODEPORT)"
            track_test false
        fi
    else
        print_status $RED "❌ Service '$SERVICE' not found"
        track_test false
    fi
done

# Test 7: Check service endpoints connectivity
print_status $YELLOW "7. Testing service endpoints..."

# For Kind clusters, services are accessible via localhost
KIND_IP="127.0.0.1"

# Test endpoints
ENDPOINTS=(
    "Prometheus:$KIND_IP:30300"
    "Grafana:$KIND_IP:30400"
    "Docker Registry:$KIND_IP:30500"
    "Jenkins:$KIND_IP:30600"
)

for endpoint in "${ENDPOINTS[@]}"; do
    NAME=$(echo $endpoint | cut -d: -f1)
    IP=$(echo $endpoint | cut -d: -f2)
    PORT=$(echo $endpoint | cut -d: -f3)

    if curl -s --connect-timeout 5 http://$IP:$PORT > /dev/null; then
        print_status $GREEN "✅ $NAME is accessible at http://$IP:$PORT"
        track_test true
    else
        print_status $RED "❌ $NAME is not accessible at http://$IP:$PORT"
        track_test false
    fi
done

# Test 8: Check RBAC permissions
print_status $YELLOW "8. Checking RBAC permissions..."
if kubectl auth can-i create pods --namespace=app --as=system:serviceaccount:iac:default &> /dev/null; then
    print_status $GREEN "✅ Jenkins service account has proper permissions in app namespace"
    track_test true
else
    print_status $RED "❌ Jenkins service account lacks permissions in app namespace"
    track_test false
fi

# Test 9: Get Jenkins admin password
print_status $YELLOW "9. Retrieving Jenkins admin password..."
JENKINS_PASSWORD=$(kubectl get secret jenkins -n iac -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode 2>/dev/null)
if [ ! -z "$JENKINS_PASSWORD" ]; then
    print_status $GREEN "✅ Jenkins admin password retrieved"
    echo "   Username: admin"
    echo "   Password: $JENKINS_PASSWORD"
    track_test true
else
    print_status $RED "❌ Could not retrieve Jenkins admin password"
    track_test false
fi

# Test 10: Check Grafana admin password
print_status $YELLOW "10. Retrieving Grafana admin password..."
GRAFANA_PASSWORD=$(kubectl get secret grafana -n iac -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null)
if [ ! -z "$GRAFANA_PASSWORD" ]; then
    print_status $GREEN "✅ Grafana admin password retrieved"
    echo "    Username: admin"
    echo "    Password: $GRAFANA_PASSWORD"
    track_test true
else
    print_status $RED "❌ Could not retrieve Grafana admin password"
    track_test false
fi

# Test 11: Validate Jenkins backend pipeline exists
print_status $YELLOW "11. Checking if Jenkins backend pipeline is created..."

# Get Jenkins admin credentials
JENKINS_USER=$(kubectl get secret jenkins -n iac -o jsonpath="{.data.jenkins-admin-user}" | base64 --decode 2>/dev/null)
JENKINS_PASSWORD_PIPELINE=$(kubectl get secret jenkins -n iac -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode 2>/dev/null)

if [ ! -z "$JENKINS_USER" ] && [ ! -z "$JENKINS_PASSWORD_PIPELINE" ]; then
    # Check if Jenkins is accessible and pipeline exists
    JENKINS_URL="http://$KIND_IP:30600"

    # First check if Jenkins is responding
    if curl -s --connect-timeout 10 --max-time 30 "$JENKINS_URL/login" > /dev/null 2>&1; then
        # Check if the devops/backend pipeline exists
        PIPELINE_CHECK=$(curl -s --connect-timeout 10 --max-time 30 \
            -u "$JENKINS_USER:$JENKINS_PASSWORD_PIPELINE" \
            "$JENKINS_URL/job/devops/job/backend/api/json" 2>/dev/null)

        if echo "$PIPELINE_CHECK" | grep -q '"name":"backend"'; then
            print_status $GREEN "✅ Jenkins backend pipeline exists in devops folder"
            track_test true
        else
            # Check if devops folder exists
            DEVOPS_FOLDER_CHECK=$(curl -s --connect-timeout 10 --max-time 30 \
                -u "$JENKINS_USER:$JENKINS_PASSWORD_PIPELINE" \
                "$JENKINS_URL/job/devops/api/json" 2>/dev/null)

            if echo "$DEVOPS_FOLDER_CHECK" | grep -q '"name":"devops"'; then
                print_status $RED "❌ Jenkins devops folder exists but backend pipeline not found"
                echo "   Available jobs in devops folder:"
                echo "$DEVOPS_FOLDER_CHECK" | grep -o '"name":"[^"]*"' | head -5
            else
                print_status $RED "❌ Jenkins devops folder not found"
                echo "   Available jobs at root level:"
                ROOT_JOBS=$(curl -s --connect-timeout 10 --max-time 30 \
                    -u "$JENKINS_USER:$JENKINS_PASSWORD_PIPELINE" \
                    "$JENKINS_URL/api/json" 2>/dev/null)
                echo "$ROOT_JOBS" | grep -o '"name":"[^"]*"' | head -5
            fi
            track_test false
        fi
    else
        print_status $RED "❌ Jenkins is not accessible at $JENKINS_URL"
        track_test false
    fi
else
    print_status $RED "❌ Could not retrieve Jenkins credentials"
    track_test false
fi


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
fi

print_status $YELLOW "Now running tofu tests..."
cd iac/src
tofu test
cd -