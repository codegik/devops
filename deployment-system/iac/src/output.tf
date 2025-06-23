output "grafana_admin_password" {
  value = "kubectl get secret --namespace iac grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
}

output "access_prometheus" {
  value       = "http://localhost:30300"
  description = "Access Prometheus using the NodePort mapped to localhost"
}

output "access_grafana" {
  value       = "http://localhost:30400"
  description = "Access Grafana using the NodePort mapped to localhost"
}


output "access_jenkins" {
  value       = "http://localhost:30600"
  description = "Access Jenkins using the NodePort mapped to localhost"
}
