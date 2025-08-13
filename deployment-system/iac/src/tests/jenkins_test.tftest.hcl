run "plan_succeeds" {
  command = plan
}

run "jenkins_release_in_infra_ns" {
  command = plan

  assert {
    condition     = helm_release.jenkins.name == "jenkins"
    error_message = "Helm release for Jenkins must be named 'jenkins'."
  }

  assert {
    condition     = helm_release.jenkins.namespace == kubernetes_namespace.infra.metadata[0].name
    error_message = "Jenkins must target the 'infra' namespace."
  }
}

run "monitoring_release_exists" {
  command = plan

  assert {
    condition     = helm_release.monitoring.name == "kube-prometheus"
    error_message = "kube-prometheus-stack helm release not found in config."
  }

  assert {
    condition     = helm_release.monitoring.namespace == kubernetes_namespace.infra.metadata[0].name
    error_message = "Monitoring stack must target the 'infra' namespace."
  }
}
