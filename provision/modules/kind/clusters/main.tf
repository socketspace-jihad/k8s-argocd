terraform {
  required_providers {
    kind = {
      source  = "kyma-incubator/kind"
      version = "0.0.11"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "default" {
  name           = "${var.name}-cluster"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = var.http_host_port
      }
      extra_port_mappings {
        container_port = 443
        host_port      = var.https_host_port
      }
    }

    node {
      role = "worker"
    }
    node {
      role = "worker"
    }
    node {
      role = "worker"
    }
  }
}

provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
}

locals {
  bootstrap_path = "../bootstrap-apps"
}

resource "kubernetes_namespace" "bootstrap-metallb" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "bootstrap-metallb"
  }
}

resource "null_resource" "deployment-metallb" {
  depends_on = [
    kubernetes_namespace.bootstrap-metallb
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/metallb/deploy.sh ${local.bootstrap_path}/metallb/manifest.yaml bootstrap-metallb"
  }
}


resource "kubernetes_namespace" "istio-system" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "istio-system"
  }
}

resource "null_resource" "istio-system" {
  depends_on = [
    kubernetes_namespace.istio-system
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/istio-system/deploy.sh ${local.bootstrap_path}/istio-system/manifest.yaml istio-system"
  }
}

resource "kubernetes_namespace" "bootstrap-argocd" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "bootstrap-argocd"
  }
}

resource "null_resource" "bootstrap-argocd" {
  depends_on = [
    kubernetes_namespace.bootstrap-metallb,
    null_resource.istio-system
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/argocd/deploy.sh ${local.bootstrap_path}/argocd/manifest.yaml bootstrap-argocd ${local.bootstrap_path}/argocd/virtual-service.yaml"
  }
}


resource "kubernetes_namespace" "prometheus" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "prometheus"
    labels = {
      istio-injection="enabled"
    }
  }
}

resource "null_resource" "prometheus" {
  depends_on = [
    kubernetes_namespace.prometheus,
    null_resource.istio-system
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/prometheus/deploy.sh ${local.bootstrap_path}/prometheus/manifest.yaml prometheus ${local.bootstrap_path}/prometheus/virtual-service.yaml"
  }
}

resource "kubernetes_namespace" "grafana" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "grafana"
    labels = {
      istio-injection="enabled"
    }
  }
}

resource "null_resource" "grafana" {
  depends_on = [
    kubernetes_namespace.grafana,
    null_resource.istio-system
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/grafana/deploy.sh ${local.bootstrap_path}/grafana/manifest.yaml grafana ${local.bootstrap_path}/grafana/virtual-service.yaml"
  }
}

resource "kubernetes_namespace" "argo-rollout" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "argo-rollout"
  }
}

resource "null_resource" "argo-rollout" {
  depends_on = [
    kubernetes_namespace.argo-rollout,
    null_resource.bootstrap-argocd,
    null_resource.istio-system
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/argo-rollout/deploy.sh"
  }
}

resource "kubernetes_namespace" "loki" {
  provider = kubernetes
  depends_on = [
    kind_cluster.default
  ]
  metadata {
    name = "loki"
  }
}

resource "null_resource" "loki" {
  depends_on = [
    kubernetes_namespace.argo-rollout,
    null_resource.istio-system,
  ]
  provisioner "local-exec" {
    command = "/bin/bash ${local.bootstrap_path}/loki/deploy.sh ${local.bootstrap_path}/loki/virtual-service.yaml"
  }
}