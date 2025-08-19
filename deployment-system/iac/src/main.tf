# Create Kind cluster
resource "kind_cluster" "default" {
  name = "kind"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 30300 # Prometheus
        host_port      = 30300
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30400 # Grafana
        host_port      = 30400
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30500 # Docker Registry
        host_port      = 30500
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30600 # Jenkins
        host_port      = 30600
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30003 # Backend (maps to app port 3000)
        host_port      = 3000
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30004 # Frontend (maps to app port 8080)
        host_port      = 8080
        protocol       = "TCP"
      }
    }
  }
}

# Wait for the cluster to be ready
resource "null_resource" "wait_for_cluster" {
  triggers = {
    cluster_id = kind_cluster.default.id
  }

  provisioner "local-exec" {
    command = "kubectl cluster-info --context=kind-kind && kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }

  depends_on = [kind_cluster.default]
}

resource "kubernetes_namespace" "iac" {
  metadata {
    name = "iac"
  }
  depends_on = [null_resource.wait_for_cluster]
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
  depends_on = [null_resource.wait_for_cluster]
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
  depends_on = [null_resource.wait_for_cluster]
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
    kubernetes_namespace.app,
    null_resource.wait_for_cluster
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
  depends_on = [null_resource.wait_for_cluster]
}

# Deploy Grafana
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.iac.metadata[0].name
  timeout    = 600
  values     = [file("../resources/grafana.yml")]
  depends_on = [helm_release.prometheus, null_resource.wait_for_cluster]
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
  depends_on = [null_resource.wait_for_cluster]
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
              - script: >
                  pipelineJob('devops/frontend') {
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
                        scriptPath('deployment-system/app/frontend/Jenkinsfile')
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
  depends_on = [null_resource.wait_for_cluster]
}
