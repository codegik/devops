#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🧪 Testing infrastructure after tofu apply..."
echo ""

# Test 1: Check if Kind cluster is running
print_status $YELLOW "1. Checking Kind cluster status..."
if kubectl cluster-info &> /dev/null; then
    print_status $GREEN "✅ Kind cluster is running"
else
    print_status $RED "❌ Kind cluster is not accessible"
    exit 1
fi

# Test 2: Check if all nodes are ready
print_status $YELLOW "2. Checking node status..."
NODE_STATUS=$(kubectl get nodes --no-headers | awk '{print $2}' | grep -v Ready | wc -l)
if [ $NODE_STATUS -eq 0 ]; then
    print_status $GREEN "✅ All nodes are ready"
    kubectl get nodes
else
    print_status $RED "❌ Some nodes are not ready"
    kubectl get nodes
fi

# Test 3: Check namespaces
print_status $YELLOW "3. Checking required namespaces..."
NAMESPACES=("iac" "app")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace $ns &> /dev/null; then
        print_status $GREEN "✅ Namespace '$ns' exists"
    else
        print_status $RED "❌ Namespace '$ns' not found"
    fi
done

# Test 4: Check Helm releases
print_status $YELLOW "4. Checking Helm releases..."
RELEASES=("prometheus" "grafana" "docker-registry" "jenkins")
for release in "${RELEASES[@]}"; do
    STATUS=$(helm status $release -n iac --output json 2>/dev/null | jq -r '.info.status' 2>/dev/null)
    if [ "$STATUS" = "deployed" ]; then
        print_status $GREEN "✅ Helm release '$release' is deployed"
    else
        print_status $RED "❌ Helm release '$release' is not deployed properly (status: $STATUS)"
    fi
done

# Test 5: Check pod status
print_status $YELLOW "5. Checking pod status in iac namespace..."
PENDING_PODS=$(kubectl get pods -n iac --no-headers | grep -v Running | grep -v Completed | wc -l)
if [ $PENDING_PODS -eq 0 ]; then
    print_status $GREEN "✅ All pods in iac namespace are running"
else
    print_status $RED "❌ Some pods are not running in iac namespace:"
    kubectl get pods -n iac | grep -v Running | grep -v Completed
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
        else
            print_status $RED "❌ Service '$SERVICE' NodePort mismatch (expected: $PORT, actual: $NODEPORT)"
        fi
    else
        print_status $RED "❌ Service '$SERVICE' not found"
    fi
done

# Test 7: Check service endpoints connectivity
print_status $YELLOW "7. Testing service endpoints..."

# Get Kind cluster IP
KIND_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

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
    else
        print_status $RED "❌ $NAME is not accessible at http://$IP:$PORT"
    fi
done

# Test 8: Check RBAC permissions
print_status $YELLOW "8. Checking RBAC permissions..."
if kubectl auth can-i create pods --namespace=app --as=system:serviceaccount:iac:default &> /dev/null; then
    print_status $GREEN "✅ Jenkins service account has proper permissions in app namespace"
else
    print_status $RED "❌ Jenkins service account lacks permissions in app namespace"
fi

# Test 9: Get Jenkins admin password
print_status $YELLOW "9. Retrieving Jenkins admin password..."
JENKINS_PASSWORD=$(kubectl get secret jenkins -n iac -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode 2>/dev/null)
if [ ! -z "$JENKINS_PASSWORD" ]; then
    print_status $GREEN "✅ Jenkins admin password retrieved"
    echo "   Username: admin"
    echo "   Password: $JENKINS_PASSWORD"
else
    print_status $RED "❌ Could not retrieve Jenkins admin password"
fi

# Test 10: Check Grafana admin password
print_status $YELLOW "10. Retrieving Grafana admin password..."
GRAFANA_PASSWORD=$(kubectl get secret grafana -n iac -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null)
if [ ! -z "$GRAFANA_PASSWORD" ]; then
    print_status $GREEN "✅ Grafana admin password retrieved"
    echo "    Username: admin"
    echo "    Password: $GRAFANA_PASSWORD"
else
    print_status $RED "❌ Could not retrieve Grafana admin password"
fi

# Summary
echo ""
print_status $BLUE "📊 Infrastructure Test Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_status $GREEN "Service URLs:"
echo "🔗 Jenkins:    http://$KIND_IP:30600"
echo "📊 Grafana:    http://$KIND_IP:30400"
echo "📈 Prometheus: http://$KIND_IP:30300"
echo "🐳 Registry:   http://$KIND_IP:30500"
echo ""
print_status $YELLOW "Next Steps:"
echo "1. Access Jenkins and verify the hello-buddy pipeline is created"
echo "2. Access Grafana and verify Prometheus datasource is configured"
echo "3. Deploy the hello-buddy application to test the complete pipeline"
echo "4. Run: kubectl get pods -A to see all running pods"
echo "5. Run: kubectl logs -f deployment/jenkins -n iac to check Jenkins logs"
