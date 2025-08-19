# tests/main.tftest.hcl

# Smoke: the plan must succeed
run "plan_succeeds" {
  command = plan
}

# Namespaces must exist
run "namespaces_exist" {
  command = plan

  assert {
    condition     = resource.kubernetes_namespace.iac.metadata[0].name == "iac"
    error_message = "Namespace 'iac' is not configured correctly."
  }

  assert {
    condition     = resource.kubernetes_namespace.app.metadata[0].name == "app"
    error_message = "Namespace 'app' is not configured correctly."
  }
}

# RBAC: Role 'app-admin' in 'app' with wildcard permissions
run "rbac_role_app_admin" {
  command = plan

  assert {
    condition     = resource.kubernetes_role.app_admin.metadata[0].namespace == resource.kubernetes_namespace.app.metadata[0].name
    error_message = "Role 'app-admin' must be in the 'app' namespace."
  }

  # At least one rule with apiGroups/resources/verbs all '*'
  assert {
    condition = anytrue([
      for r in resource.kubernetes_role.app_admin.rule :
      contains(r.api_groups, "*") && contains(r.resources, "*") && contains(r.verbs, "*")
    ])
    error_message = "Role 'app-admin' must allow apiGroups='*', resources='*', verbs='*'."
  }
}

# RBAC: RoleBinding points to Role in 'app' and SA 'default' in 'iac'
run "rbac_rolebinding_jenkins_app_admin" {
  command = plan

  assert {
    condition     = resource.kubernetes_role_binding.jenkins_app_admin.metadata[0].namespace == resource.kubernetes_namespace.app.metadata[0].name
    error_message = "RoleBinding 'jenkins-app-admin' must be in the 'app' namespace."
  }

  assert {
    condition     = resource.kubernetes_role_binding.jenkins_app_admin.role_ref[0].kind == "Role"
    error_message = "RoleBinding 'jenkins-app-admin' must have role_ref.kind='Role'."
  }

  assert {
    condition     = resource.kubernetes_role_binding.jenkins_app_admin.role_ref[0].name == resource.kubernetes_role.app_admin.metadata[0].name
    error_message = "RoleBinding 'jenkins-app-admin' must reference the Role 'app-admin'."
  }

  assert {
    condition     = resource.kubernetes_role_binding.jenkins_app_admin.subject[0].kind == "ServiceAccount"
    error_message = "RoleBinding 'jenkins-app-admin' subject must be a ServiceAccount."
  }

  assert {
    condition     = resource.kubernetes_role_binding.jenkins_app_admin.subject[0].name == "default"
    error_message = "RoleBinding 'jenkins-app-admin' must target ServiceAccount 'default'."
  }

  assert {
    condition     = resource.kubernetes_role_binding.jenkins_app_admin.subject[0].namespace == "iac"
    error_message = "RoleBinding 'jenkins-app-admin' ServiceAccount must be in namespace 'iac'."
  }
}

# Prometheus: release name, namespace, NodePort 30300
run "prometheus_release_config" {
  command = plan

  assert {
    condition     = resource.helm_release.prometheus.name == "prometheus"
    error_message = "Helm release for Prometheus must be named 'prometheus'."
  }

  assert {
    condition     = resource.helm_release.prometheus.namespace == resource.kubernetes_namespace.iac.metadata[0].name
    error_message = "Prometheus must be deployed in namespace 'iac'."
  }

  assert {
    condition = length([
      for s in resource.helm_release.prometheus.set :
      s if s.name == "server.service.type" && s.value == "NodePort"
    ]) > 0
    error_message = "Prometheus must have service.type=NodePort (server.service.type)."
  }

  assert {
    condition = length([
      for s in resource.helm_release.prometheus.set :
      s if s.name == "server.service.nodePort" && s.value == "30300"
    ]) > 0
    error_message = "Prometheus must expose NodePort 30300 (server.service.nodePort)."
  }
}

# Grafana: release name, namespace, NodePort 30400
run "grafana_release_config" {
  command = plan

  assert {
    condition     = resource.helm_release.grafana.name == "grafana"
    error_message = "Helm release for Grafana must be named 'grafana'."
  }

  assert {
    condition     = resource.helm_release.grafana.namespace == resource.kubernetes_namespace.iac.metadata[0].name
    error_message = "Grafana must be deployed in namespace 'iac'."
  }

  assert {
    condition = length([
      for s in resource.helm_release.grafana.set :
      s if s.name == "service.type" && s.value == "NodePort"
    ]) > 0
    error_message = "Grafana must have service.type=NodePort."
  }

  assert {
    condition = length([
      for s in resource.helm_release.grafana.set :
      s if s.name == "service.nodePort" && s.value == "30400"
    ]) > 0
    error_message = "Grafana must expose NodePort 30400."
  }
}

# Docker Registry: release name, namespace, NodePort 30500, persistence disabled
run "docker_registry_release_config" {
  command = plan

  assert {
    condition     = resource.helm_release.docker_registry.name == "docker-registry"
    error_message = "Helm release for Docker Registry must be named 'docker-registry'."
  }

  assert {
    condition     = resource.helm_release.docker_registry.namespace == resource.kubernetes_namespace.iac.metadata[0].name
    error_message = "Docker Registry must be deployed in namespace 'iac'."
  }

  assert {
    condition = length([
      for s in resource.helm_release.docker_registry.set :
      s if s.name == "service.type" && s.value == "NodePort"
    ]) > 0
    error_message = "Docker Registry must have service.type=NodePort."
  }

  assert {
    condition = length([
      for s in resource.helm_release.docker_registry.set :
      s if s.name == "service.nodePort" && s.value == "30500"
    ]) > 0
    error_message = "Docker Registry must expose NodePort 30500."
  }

  assert {
    condition = length([
      for s in resource.helm_release.docker_registry.set :
      s if s.name == "persistence.enabled" && s.value == "false"
    ]) > 0
    error_message = "Docker Registry must have persistence.enabled=false."
  }
}

# Jenkins: release name, namespace, NodePort 30600
run "jenkins_release_config" {
  command = plan

  assert {
    condition     = resource.helm_release.jenkins.name == "jenkins"
    error_message = "Helm release for Jenkins must be named 'jenkins'."
  }

  assert {
    condition     = resource.helm_release.jenkins.namespace == resource.kubernetes_namespace.iac.metadata[0].name
    error_message = "Jenkins must be deployed in namespace 'iac'."
  }

  assert {
    condition = length([
      for s in resource.helm_release.jenkins.set :
      s if s.name == "controller.serviceType" && s.value == "NodePort"
    ]) > 0
    error_message = "Jenkins must have controller.serviceType=NodePort."
  }

  assert {
    condition = length([
      for s in resource.helm_release.jenkins.set :
      s if s.name == "controller.servicePort" && s.value == "8080"
    ]) > 0
    error_message = "Jenkins must have controller.servicePort=8080."
  }

  assert {
    condition = length([
      for s in resource.helm_release.jenkins.set :
      s if s.name == "controller.nodePort" && s.value == "30600"
    ]) > 0
    error_message = "Jenkins must expose NodePort 30600."
  }
}
