output "grafana_admin_password" {
  value = "kubectl get secret --namespace iac grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
}

output "access_prometheus" {
  value = "kubectl port-forward -n iac svc/prometheus-server 9090:80"
}

output "access_grafana" {
  value = "kubectl port-forward -n iac svc/grafana 3000:80"
}

output "access_prometheus_nodeport" {
  value       = "http://localhost:30300"
  description = "Access Prometheus using the NodePort mapped to localhost"
}

output "access_grafana_nodeport" {
  value       = "http://localhost:30400"
  description = "Access Grafana using the NodePort mapped to localhost"
}

output "access_docker_registry_nodeport" {
  value       = "http://localhost:30500"
  description = "Access Docker Registry using the NodePort mapped to localhost"
}

output "access_jenkins_nodeport" {
  value       = "http://localhost:30600"
  description = "Access Jenkins using the NodePort mapped to localhost"
}

output "kind_port_forwarding_command" {
  value       = "docker port kind-control-plane | grep 30"
  description = "Command to check which host ports are mapped to the NodePorts"
}
