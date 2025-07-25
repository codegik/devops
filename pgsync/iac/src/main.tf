
# Create namespace for PGSync
resource "kubernetes_namespace" "pgsync" {
  metadata {
    name = "pgsync"
  }
}

# Deploy PostgreSQL
resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.pgsync.metadata[0].name
  timeout    = 600

  set = [
    {
      name  = "auth.postgresPassword"
      value = "postgres123"
    },
    {
      name  = "auth.username"
      value = "pgsync"
    },
    {
      name  = "auth.password"
      value = "pgsync123"
    },
    {
      name  = "auth.database"
      value = "pgsync_db"
    },
    {
      name  = "primary.service.type"
      value = "NodePort"
    },
    {
      name  = "primary.service.nodePorts.postgresql"
      value = "30700"
    },
    {
      name  = "primary.persistence.enabled"
      value = "true"
    },
    {
      name  = "primary.persistence.size"
      value = "8Gi"
    },
    {
      name  = "primary.initdb.scriptsConfigMap"
      value = kubernetes_config_map.postgresql_init.metadata[0].name
    }
  ]

  depends_on = [
    kubernetes_config_map.postgresql_init
  ]
}

# Deploy OpenSearch
resource "helm_release" "opensearch" {
  name       = "opensearch"
  repository = "https://opensearch-project.github.io/helm-charts/"
  chart      = "opensearch"
  namespace  = kubernetes_namespace.pgsync.metadata[0].name
  timeout    = 900

  set = [
    {
      name  = "clusterName"
      value = "opensearch-cluster"
    },
    {
      name  = "nodeGroup"
      value = "master"
    },
    {
      name  = "masterService"
      value = "opensearch-cluster-master"
    },
    {
      name  = "replicas"
      value = "1"
    },
    {
      name  = "minimumMasterNodes"
      value = "1"
    },
    {
      name  = "service.type"
      value = "NodePort"
    },
    {
      name  = "service.nodePort"
      value = "30800"
    },
    {
      name  = "config.opensearch\\.yml.cluster\\.initial_master_nodes"
      value = "opensearch-cluster-master-0"
    },
    {
      name  = "config.opensearch\\.yml.discovery\\.seed_hosts"
      value = "opensearch-cluster-master-headless"
    },
    {
      name  = "singleNode"
      value = "true"
    },
    {
      name  = "persistence.enabled"
      value = "true"
    },
    {
      name  = "persistence.size"
      value = "8Gi"
    }
  ]
}

# Deploy OpenSearch Dashboard
resource "helm_release" "opensearch_dashboards" {
  name       = "opensearch-dashboards"
  repository = "https://opensearch-project.github.io/helm-charts/"
  chart      = "opensearch-dashboards"
  namespace  = kubernetes_namespace.pgsync.metadata[0].name
  timeout    = 600
  depends_on = [helm_release.opensearch]

  set = [
    {
      name  = "opensearchHosts"
      value = "https://opensearch-cluster-master:9200"
    },
    {
      name  = "service.type"
      value = "NodePort"
    },
    {
      name  = "service.nodePort"
      value = "30900"
    },
    {
      name  = "replicaCount"
      value = "1"
    }
  ]
}


# Deploy PGSync
resource "kubernetes_deployment" "pgsync" {
  metadata {
    name      = "pgsync"
    namespace = kubernetes_namespace.pgsync.metadata[0].name
    labels = {
      app = "pgsync"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "pgsync"
      }
    }

    template {
      metadata {
        labels = {
          app = "pgsync"
        }
      }

      spec {
        container {
          image = "toluaina/pgsync:latest"
          name  = "pgsync"

          env {
            name  = "PG_USER"
            value = "pgsync"
          }
          env {
            name  = "PG_PASSWORD"
            value = "pgsync123"
          }
          env {
            name  = "PG_HOST"
            value = "postgresql.pgsync.svc.cluster.local"
          }
          env {
            name  = "PG_PORT"
            value = "5432"
          }
          env {
            name  = "PG_DATABASE"
            value = "pgsync_db"
          }
          env {
            name  = "ELASTICSEARCH_HOST"
            value = "opensearch-cluster-master.pgsync.svc.cluster.local"
          }
          env {
            name  = "ELASTICSEARCH_PORT"
            value = "9200"
          }
          env {
            name  = "ELASTICSEARCH_SCHEME"
            value = "https"
          }
          env {
            name  = "ELASTICSEARCH_VERIFY_CERTS"
            value = "false"
          }
          env {
            name  = "REDIS_HOST"
            value = "redis.pgsync.svc.cluster.local"
          }
          env {
            name  = "REDIS_PORT"
            value = "6379"
          }

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "pgsync-config"
            mount_path = "/app/schema.json"
            sub_path   = "schema.json"
          }
        }

        volume {
          name = "pgsync-config"
          config_map {
            name = kubernetes_config_map.pgsync_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.postgresql,
    helm_release.opensearch,
    helm_release.redis
  ]
}

# PGSync Service
resource "kubernetes_service" "pgsync" {
  metadata {
    name      = "pgsync"
    namespace = kubernetes_namespace.pgsync.metadata[0].name
  }

  spec {
    selector = {
      app = "pgsync"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      node_port   = 31000
    }

    type = "NodePort"
  }
}

# Deploy Redis (required by PGSync)
resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = kubernetes_namespace.pgsync.metadata[0].name
  timeout    = 600

  set = [
    {
      name  = "auth.enabled"
      value = "false"
    },
    {
      name  = "master.persistence.enabled"
      value = "true"
    },
    {
      name  = "master.persistence.size"
      value = "2Gi"
    }
  ]
}

# PGSync Configuration
resource "kubernetes_config_map" "pgsync_config" {
  metadata {
    name      = "pgsync-config"
    namespace = kubernetes_namespace.pgsync.metadata[0].name
  }

  data = {
    "schema.json" = file("../resources/pgsync-schema.json")
  }
}

# PostgreSQL Initialization Configuration
resource "kubernetes_config_map" "postgresql_init" {
  metadata {
    name      = "postgresql-init"
    namespace = kubernetes_namespace.pgsync.metadata[0].name
  }

  data = {
    "init.sql" = file("../resources/postgresql-init.sql")
  }
}
