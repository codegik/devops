# tests/main.tftest.hcl

# Smoke: the plan must succeed
run "plan_succeeds" {
  command = plan
}

# Namespaces must exist
run "namespaces_exist" {
  command = plan

  assert {
    condition     = kubernetes_namespace.iac.metadata[0].name == "iac"
    error_message = "Namespace 'iac' is not configured correctly."
  }

  assert {
    condition     = kubernetes_namespace.app.metadata[0].name == "app"
    error_message = "Namespace 'app' is not configured correctly."
  }
}

# RBAC: Role admin in the 'app' namespace with full permissions
run "rbac_role_app_admin" {
  command = plan

  assert {
    condition     = kubernetes_role.app_admin.metadata[0].namespace == kubernetes_namespace.app.metadata[0].name
    error_message = "Role 'app-admin' must be in the 'app' namespace."
  }

  # Check that the first (and only) rule uses wildcard for apiGroups/resources/verbs
  assert {
    condition     = kubernetes_role.app_admin.rule[0].api_groups[0] == "*"
    error_message = "Role 'app-admin' must allow apiGroups='*'."
  }
  assert {
    condition     = kubernetes_role.app_admin.rule[0].resources[0] == "*"
    error_message = "Role 'app-admin' must allow resources='*'."
  }
  assert {
    condition     = kubernetes_role.app_admin.rule[0].verbs[0] == "*"
    error_message = "Role 'app-admin' must allow verbs='*'."
  }
}

# RBAC: RoleBinding must point to Role in 'app' and ServiceAccount 'default' in 'iac'
run "rbac_rolebinding_jenkins_app_admin" {
  command = plan

  assert {
    condition     = kubernetes_role_binding.jenkins_app_admin.metadata[0].namespace == kubernetes_namespace.app.metadata[0].name
    error_message = "RoleBinding 'jenkins-app-admin' must be in the 'app' namespace."
  }

  assert {
    condition     = kubernetes_role_binding.jenkins_app_admin.role_ref[0].kind == "Role"
    error_message = "RoleBinding 'jenkins-app-admin' must have role_ref.kind='Role'."
  }

  assert {
    condition     = kubernetes_role_binding.jenkins_app_admin.role_ref[0].name == kubernetes_role.app_admin.metadata[0].name
    error_message = "RoleBinding 'jenkins-app-admin' must reference the Role 'app-admin'."
  }

  assert {
    condition     = kubernetes_role_binding.jenkins_app_admin.subject[0].kind == "ServiceAccount"
    error_message = "RoleBinding 'jenkins-app-admin' subject must be a ServiceAccount."
  }

  assert {
    condition     = kubernetes_role_binding.jenkins_app_admin.subject[0].name == "default"
    error_message = "RoleBinding 'jenkins-app-admin' must target ServiceAccount 'default'."
  }

  assert {
    condition     = kubernetes_role_binding.jenkins_app_admin.subject[0].namespace == "iac"
    error_message = "RoleBinding 'jenkins-app-admin' ServiceAccount must be in namespace 'iac'."
  }
}

# Prometheus: release name, namespace, NodePort 30300
run "prometheus_release_config" {
  command = plan

  assert {
    condition     = helm_release.prometheus.name == "prometheus"
    error_message = "Helm release for Prometheus must be named 'prometheus'."
  }

  assert {
    condition     = helm_release.prometheus.namespace == kubernetes_namespace.iac.metadata[0].name
    error_message = "Prometheus must be deployed in namespace 'iac'."
  }

  # set[0] = server.service.type, set[1] = server.service.nodePort
  assert {
    condition     = helm_release.prometheus.set[0].name == "server.service.type" && helm_release.prometheus.set[0].value == "NodePort"
    error_message = "Prometheus must have service.type=NodePort."
  }

  assert {
    condition     = helm_release.prometheus.set[1].name == "server.service.nodePort" && helm_release.prometheus.set[1].value == "30300"
    error_message = "Prometheus must expose NodePort 30300."
  }
}

# Grafana: release name, namespace, NodePort 30400
run "grafana_release_config" {
  command = plan

  assert {
    condition     = helm_release.grafana.name == "grafana"
    error_message = "Helm release for Grafana must be named 'grafana'."
  }

  assert {
    condition     = helm_release.grafana.namespace == kubernetes_namespace.iac.metadata[0].name
    error_message = "Grafana must be deployed in namespace 'iac'."
  }

  # set[0] = service.type, set[1] = service.nodePort
  assert {
    condition     = helm_release.grafana.set[0].name == "service.type" && helm_release.grafana.set[0].value == "NodePort"
    error_message = "Grafana must have service.type=NodePort."
  }

  assert {
    condition     = helm_release.grafana.set[1].name == "service.nodePort" && helm_release.grafana.set[1].value == "30400"
    error_message = "Grafana must expose NodePort 30400."
  }
}

# Docker Registry: release name, namespace, NodePort 30500, persistence disabled
run "docker_registry_release_config" {
  command = plan

  assert {
    condition     = helm_release.docker_registry.name == "docker-registry"
    error_message = "Helm release for Docker Registry must be named 'docker-registry'."
  }

  assert {
    condition     = helm_release.docker_registry.namespace == kubernetes_namespace.iac.metadata[0].name
    error_message = "Docker Registry must be deployed in namespace 'iac'."
  }

  # set[0] = service.type, set[1] = service.nodePort, set[2] = persistence.enabled
  assert {
    condition     = helm_release.docker_registry.set[0].name == "service.type" && helm_release.docker_registry.set[0].value == "NodePort"
    error_message = "Docker Registry must have service.type=NodePort."
  }

  assert {
    condition     = helm_release.docker_registry.set[1].name == "service.nodePort" && helm_release.docker_registry.set[1].value == "30500"
    error_message = "Docker Registry must expose NodePort 30500."
  }

  assert {
    condition     = helm_release.docker_registry.set[2].name == "persistence.enabled" && helm_release.docker_registry.set[2].value == "false"
    error_message = "Docker Registry must have persistence.enabled=false."
  }
}

# Jenkins: release name, namespace, NodePort 30600
run "jenkins_release_config" {
  command = plan

  assert {
    condition     = helm_release.jenkins.name == "jenkins"
    error_message = "Helm release for Jenkins must be named 'jenkins'."
  }

  assert {
    condition     = helm_release.jenkins.namespace == kubernetes_namespace.iac.metadata[0].name
    error_message = "Jenkins must be deployed in namespace 'iac'."
  }

  # set[0] = controller.serviceType, set[1] = controller.servicePort, set[2] = controller.nodePort
  assert {
    condition     = helm_release.jenkins.set[0].name == "controller.serviceType" && helm_release.jenkins.set[0].value == "NodePort"
    error_message = "Jenkins must have controller.serviceType=NodePort."
  }

  assert {
    condition     = helm_release.jenkins.set[1].name == "controller.servicePort" && helm_release.jenkins.set[1].value == "8080"
    error_message = "Jenkins must have controller.servicePort=8080."
  }

  assert {
    condition     = helm_release.jenkins.set[2].name == "controller.nodePort" && helm_release.jenkins.set[2].value == "30600"
    error_message = "Jenkins must expose NodePort 30600."
  }
}
