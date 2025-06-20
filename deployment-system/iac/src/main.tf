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
  timeout    = 900 # Increase timeout to 15 minutes

  set        = [
    {
      name  = "server.service.type"
      value = "NodePort"
    },
    {
      name  = "server.service.nodePort"
      value = "30300"
    }
  ]
}

# Deploy Grafana
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.iac.metadata[0].name
  timeout    = 600
  set        = [
    {
      name  = "service.type"
      value = "NodePort"
    },
    {
      name  = "service.nodePort"
      value = "30400"
    }
  ]
  # Configure Grafana with Prometheus datasource
  values     = [file("../resources/grafana.yml")]
  depends_on = [helm_release.prometheus]
}


# Deploy Docker Registry
resource "helm_release" "docker_registry" {
  name       = "docker-registry"
  repository = "https://charts.helm.sh/stable"
  chart      = "docker-registry"
  namespace  = kubernetes_namespace.iac.metadata[0].name
  timeout    = 600
  set        = [
    {
      name  = "service.type"
      value = "NodePort"
    },
    {
      name  = "service.nodePort"
      value = "30500"
    }
  ]
}

# Deploy Jenkins
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.iac.metadata[0].name
  timeout    = 900
  set        = [
    {
      name  = "controller.serviceType"
      value = "NodePort"
    },
    {
      name  = "controller.servicePort"
      value = "8080"
    },
    {
      name  = "controller.targetPort"
      value = "8080"
    },
    {
      name  = "controller.nodePort"
      value = "30600"
    }
  ]
}
