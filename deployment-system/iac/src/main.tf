
resource "kubernetes_namespace" "iac" {
  metadata {
    name = "iac"
  }
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}


# Deploy Prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.iac.metadata[0].name
}

# Deploy Grafana
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.iac.metadata[0].name

  # Configure Grafana with Prometheus datasource
  values     = [file("../resources/grafana.yml")]
  depends_on = [helm_release.prometheus]
}
