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
  timeout    = 1800 # Increase timeout to 30 minutes
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
                  pipelineJob('devops/hello-buddy') {
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
                        scriptPath('deployment-system/app/hello-buddy/Jenkinsfile')
                      }
                    }
                  }

      installPlugins:
        - git:latest
        - workflow-aggregator:latest
        - job-dsl:latest
        - configuration-as-code:latest
        - docker-workflow:latest
    EOT
  ]
}
