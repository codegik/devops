
output "grafana_admin_password" {
  value = "kubectl get secret --namespace iac grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
}

output "access_prometheus" {
  value = "kubectl port-forward -n iac svc/prometheus-server 9090:80"
}

output "access_grafana" {
  value = "kubectl port-forward -n iac svc/grafana 3000:80"
}