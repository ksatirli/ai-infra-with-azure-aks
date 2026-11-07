required_providers {
  # see https://registry.terraform.io/providers/Azure/azapi/latest/docs
  azapi = {
    source  = "Azure/azapi"
    version = "~> 2.13"
  }

  # see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
  azurerm = {
    source = "hashicorp/azurerm"
    # AVM currently excludes 5.x
    version = ">= 4.81.0, < 5.0.0"
  }

  # see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
  kubernetes = {
    source  = "hashicorp/kubernetes"
    version = "~> 3.5"
  }

  # see https://registry.terraform.io/providers/Azure/modtm/latest/docs
  modtm = {
    source  = "Azure/modtm"
    version = "~> 0.4"
  }

  # see https://registry.terraform.io/providers/hashicorp/random/latest/docs
  random = {
    source  = "hashicorp/random"
    version = "~> 3.9"
  }

  terraform = {
    source = "terraform.io/builtin/terraform"
  }

  # see https://registry.terraform.io/providers/hashicorp/time/latest/docs
  time = {
    source  = "hashicorp/time"
    version = "~> 0.14"
  }
}

# see https://developer.hashicorp.com/terraform/language/stacks/deploy/authenticate
provider "azurerm" "this" {
  config {
    features {}

    use_cli         = false
    use_oidc        = true
    oidc_token      = var.identity_token
    client_id       = var.client_id
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id

    resource_provider_registrations = "none"
  }
}

# see https://developer.hashicorp.com/terraform/language/stacks/deploy/authenticate
provider "azapi" "this" {
  config {
    use_cli         = false
    use_oidc        = true
    oidc_token      = var.identity_token
    client_id       = var.client_id
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
  }
}

# see https://developer.hashicorp.com/terraform/language/stacks/component/declare-providers
provider "kubernetes" "this" {
  config {
    host                   = component.aks.host
    cluster_ca_certificate = component.aks.cluster_ca_certificate

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "sh"
      args = ["-c", <<-EOT
        set -eu
        response=$(curl --silent --show-error --request POST \
          "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" \
          --data-urlencode "grant_type=client_credentials" \
          --data-urlencode "client_id=$AZURE_CLIENT_ID" \
          --data-urlencode "scope=6dae42f8-4368-4678-94ff-3960e28e3630/.default" \
          --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
          --data-urlencode "client_assertion=$AZURE_CLIENT_ASSERTION")
        token=$(printf '%s' "$response" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
        if [ -z "$token" ]; then
          echo "aks-token: token exchange failed: $response" >&2
          exit 1
        fi
        printf '{"apiVersion":"client.authentication.k8s.io/v1beta1","kind":"ExecCredential","status":{"token":"%s"}}\n' "$token"
      EOT
      ]

      env = {
        AZURE_TENANT_ID        = var.tenant_id
        AZURE_CLIENT_ID        = var.client_id
        AZURE_CLIENT_ASSERTION = var.identity_token
      }
    }
  }
}

# see https://registry.terraform.io/providers/Azure/modtm/latest/docs
provider "modtm" "this" {
  config {
    enabled = false
  }
}

# see https://registry.terraform.io/providers/hashicorp/random/latest/docs
provider "random" "this" {}

# see https://developer.hashicorp.com/terraform/language/resources/terraform-data
provider "terraform" "this" {}

# see https://registry.terraform.io/providers/hashicorp/time/latest/docs
provider "time" "this" {}
