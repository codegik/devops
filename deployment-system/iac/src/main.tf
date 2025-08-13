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

# Grant Jenkins permissions in the app namespace
resource "kubernetes_role" "app_admin" {
  metadata {
    name      = "app-admin"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "jenkins_app_admin" {
  metadata {
    name      = "jenkins-app-admin"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.app_admin.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "iac"
  }
  depends_on = [
    kubernetes_role.app_admin,
    kubernetes_namespace.app
  ]
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
  values     = [file("../resources/grafana.yml")]
  depends_on = [helm_release.prometheus]
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
}


# Deploy Docker Registry
resource "helm_release" "docker_registry" {
  name       = "docker-registry"
  repository = "https://helm.twun.io"
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
    },
    {
      name  = "persistence.enabled"
      value = "false"
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
      name  = "controller.nodePort"
      value = "30600"
    }
  ]
  values    = [
    <<-EOT
    controller:
      serviceType: NodePort
      servicePort: 8080
      nodePort: 30600

      JCasC:
        configScripts:
          jobs: |
            jobs:
              - script: >
                  folder('devops') {
                    description('DevOps Jobs')
                  }
              - script: >
                  pipelineJob('devops/backend') {
                    definition {
                      cpsScm {
                        scm {
                          git {
                            remote {
                              url('https://github.com/codegik/devops.git')
                            }
                            branch('*/master')
                          }
                        }
                        scriptPath('deployment-system/app/backend/Jenkinsfile')
                      }
                    }
                  }

      installPlugins:
        - git:latest
        - workflow-aggregator:latest
        - job-dsl:latest
        - configuration-as-code:latest
        - kubernetes:latest
        - kubernetes-cli:latest
    EOT
  ]
}
