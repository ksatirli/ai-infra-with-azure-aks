# see https://learn.microsoft.com/azure/aks/deployment-safeguards

# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1
resource "kubernetes_namespace_v1" "chat" {
  metadata {
    name = var.namespace
  }
}

# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1
resource "kubernetes_service_account_v1" "chat_api" {
  metadata {
    name      = local.sa_name
    namespace = kubernetes_namespace_v1.chat.metadata[0].name

    annotations = {
      "azure.workload.identity/client-id" = module.chat_api_identity.client_id
    }
  }
}

# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1
resource "kubernetes_deployment_v1" "chat_api" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.chat.metadata[0].name
    labels    = { app = local.app_name }
  }

  wait_for_rollout = false

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = local.app_name }
    }

    template {
      metadata {
        labels = {
          app                           = local.app_name
          "azure.workload.identity/use" = "true"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.chat_api.metadata[0].name

        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          run_as_group    = 10001

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "topology.kubernetes.io/zone"
          when_unsatisfiable = "ScheduleAnyway"

          label_selector {
            match_labels = { app = local.app_name }
          }
        }

        container {
          name  = local.app_name
          image = local.app_image

          port {
            name           = "http"
            container_port = 8080
          }

          env {
            name  = "FOUNDRY_BASE_URL"
            value = var.inference_base_url
          }

          env {
            name  = "FOUNDRY_DEPLOYMENT"
            value = var.model_deployment_name
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.chat_api_foundry]
}

# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1
resource "kubernetes_service_v1" "chat_api" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.chat.metadata[0].name
  }

  spec {
    type     = "LoadBalancer"
    selector = { app = local.app_name }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
  }
}
