# AI Infrastructure with Azure AKS

Demo for **Building AI infrastructure with AKS and Infrastructure as Code**: deploy
Microsoft Foundry and an AKS Automatic workload that uses it, with an HCP Terraform
Stack and Azure Verified Modules, in a way that no secret reaches the pipeline.

- **Microsoft Foundry** (PaaS) hosts the model: an AI Services account with
  API keys disabled, one project and **IBM Granite 4.2 30B** on Foundry
  **managed compute** (one dedicated A100, served through the account's
  OpenAI-compatible endpoint).
- **AKS Automatic** runs a small chat API that calls Foundry using
  **workload identity**, so the pod has no key.
- **A Terraform Stack** in HCP Terraform deploys both. Every plan and apply gets a
  short-lived **identity token**, which Azure exchanges for an access token.
- **GitHub Actions** builds the image and pushes it to ACR with **OIDC** too.

No static token exists anywhere: not on the Stack, not in state, not in GitHub.
The only long-lived sessions are the operator's own CLI logins, used once by the
local bootstrap.

## Architecture

```mermaid
flowchart LR
  OP([Operator laptop<br/>az · terraform · gh logins])

  subgraph HCP["HCP Terraform · ksatirli"]
    subgraph ST["Stack: ai-infra · deployment: westus3"]
      F[component.foundry]
      K[component.aks]
      C[component.chat_api]
      F -- outputs --> C
      K -- outputs --> C
    end
    VS[(variable set<br/>ai-infra-bootstrap)]
    VS -- store --> ST
  end

  subgraph GH["GitHub · ksatirli/ai-infra-with-azure-aks"]
    A[Actions: build-chat-api<br/>environment: production]
  end

  subgraph AZ["Azure · westus3"]
    ID[Managed identities<br/>+ federated credentials]
    AIF[Foundry account<br/>local auth disabled<br/>Granite on managed compute]
    AKS[AKS Automatic]
    ACR[(Container Registry)]
    POD[chat-api pods]
    AKS --- POD
  end

  OP -- bootstrap/ (local) --> ID & HCP & GH
  ST -- identity token --> AIF & AKS & ACR
  A -- OIDC, AcrPush --> ACR
  POD -- workload identity --> AIF
  AKS -- kubelet identity, AcrPull --> ACR
```

| Layer | Path | Runs where, as | Creates |
| --- | --- | --- | --- |
| Bootstrap | `bootstrap/` | locally, with your `az`, `terraform` and `gh` logins | resource groups, the Stack identity, the GitHub Actions identity, role assignments, the HCP Terraform project, Stack and variable set, the GitHub environment and its variables |
| Stack | `*.tfcomponent.hcl`, `*.tfdeploy.hcl` | HCP Terraform, `id-aiaks-stack` via identity token | one `westus3` deployment of the three components below |
| ↳ foundry | `components/foundry/` | | Foundry account, project, Granite managed compute deployment |
| ↳ aks | `components/aks/` | | AKS Automatic, ACR, kubelet `AcrPull` |
| ↳ chat_api | `components/chat-api/` | | chat API identity and Foundry role, Kubernetes namespace, service account, deployment, service |
| App | `app/`, `.github/workflows/` | GitHub Actions, `id-aiaks-github-actions` via OIDC | `chat-api` image in ACR |

The `chat_api` component configures its Kubernetes provider from the cluster the
`aks` component creates in the same run. HCP Terraform **defers** it until the
cluster exists, then plans it again, so a first deployment needs no `-target`.

## Azure Verified Modules

| Module | Version | Used in |
| --- | --- | --- |
| [`avm-res-resources-resourcegroup`](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm) | 0.5.0 | bootstrap |
| [`avm-res-managedidentity-userassignedidentity`](https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm) | 0.6.0 | bootstrap, chat_api |
| [`avm-ptn-aiml-ai-foundry`](https://registry.terraform.io/modules/Azure/avm-ptn-aiml-ai-foundry/azurerm) | 0.14.0 | foundry |
| [`avm-res-containerservice-managedcluster`](https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm) | 0.9.0 | aks |
| [`avm-res-containerregistry-registry`](https://registry.terraform.io/modules/Azure/avm-res-containerregistry-registry/azurerm) | 0.9.0 | aks |

The Granite deployment (`Microsoft.CognitiveServices/accounts/managedComputeDeployments`,
API `2026-09-15-preview`) is not covered by an AVM module yet, so the `foundry`
component creates it with a single `azapi_resource` on the account the AVM pattern
module builds.

All modules require `azurerm` 4.x, so the configs pin `>= 4.81.0, < 5.0.0` (the
latest 4.x) even though 5.x is out. Every other provider is on its latest release.

## The trust chain

Every hop uses a federated credential: a token from one issuer is exchanged for
a short-lived Entra ID token, and that exchange only works for one exact subject.

| Caller | Token issuer | Trusted subject | Azure identity | Can do |
| --- | --- | --- | --- | --- |
| Stack plan / apply | `app.terraform.io` | `organization:ksatirli:project:ai-infra-with-azure-aks:stack:ai-infra:deployment:westus3:operation:{plan,apply}` | stack | Contributor and AKS RBAC Cluster Admin on the workload resource group; may assign only `AcrPull` and `Foundry User` |
| Image build | `token.actions.githubusercontent.com` | `repo:ksatirli@<owner id>/ai-infra-with-azure-aks@<repo id>:environment:production` (GitHub's immutable subject) | github-actions | Reader and `AcrPush` on the workload resource group |
| chat-api pod | AKS OIDC issuer | `system:serviceaccount:chat:chat-api` | chat-api | `Foundry User` (formerly `Azure AI User`) on the Foundry account |

Identities live in their own resource group, so the Stack cannot change its own
identity or federated credentials.

### Ephemeral by design

| Credential | How it stays out of state |
| --- | --- |
| GitHub CLI token (bootstrap) | ephemeral input variable `github_token` |
| HCP Terraform CLI login (bootstrap) | read by the `tfe` provider from the CLI credentials file |
| Azure CLI login (bootstrap) | used by `azurerm` / `azapi` directly |
| Stack Azure tokens | `identity_token "azure"`, passed to an `ephemeral` Stack variable and used only in provider config |
| AKS API token | exec plugin in `providers.tfcomponent.hcl` that swaps the identity token for an Entra ID token on the runner |
| Pod token for Foundry (Granite) | projected service account token, exchanged by `DefaultAzureCredential` |
| GitHub Actions Azure token | GitHub OIDC via `azure/login` |

The cluster CA certificate is read with a regular (non-ephemeral) data source,
because component outputs cannot be ephemeral. An Entra ID cluster's user
kubeconfig holds only the server URL and the public CA, never credentials.

## Prerequisites

- An Azure subscription where you are Owner (or Contributor and User Access Administrator),
  with managed compute A100 quota (see Notes).
- The `ksatirli` HCP Terraform organization, with permission to manage projects.
- The [HCP Terraform GitHub App](https://developer.hashicorp.com/terraform/cloud-docs/vcs/github-app)
  installed on `ksatirli` with access to this repository.
- `az`, `gh`, and `terraform` ≥ 1.17.

## Run it

```sh
# 1. Bootstrap, locally, with your own CLI sessions
az login
terraform login
gh auth login

cd bootstrap
terraform init
TF_VAR_github_token="$(gh auth token)" \
TF_VAR_subscription_id="$(az account show --query id -o tsv)" \
terraform apply

# 2. HCP Terraform fetches the Stack configuration, plans the westus3
#    deployment and auto-approves it; the deferred chat_api plan follows.

# 3. Build and push the image
gh workflow run build-chat-api
```

Then call the API using the `try_it` output of the `westus3` deployment:

```sh
curl -s -X POST http://<ip>/chat -H 'content-type: application/json' \
  -d '{"message":"Hello from AKS Automatic"}'
```

Until the image exists, the chat API pods wait in `ImagePullBackOff`; they start
on their own once the workflow has pushed it.

To change the Stack locally, run `terraform stacks init` and
`terraform stacks validate` in the repository root.

## Demo flow (15 minutes)

1. **The problem (1 min):** client secrets and one-off setup on new AI platforms.
2. **Bootstrap (3 min):** the federated credential subjects, the variable set the
   Stack reads, and the ephemeral `github_token`: the trust is the only thing set
   up by hand, and none of it is a secret.
3. **The Stack (3 min):** `identity_token`, the `ephemeral` variable it feeds, and
   the three components wired by their outputs.
4. **Foundry (3 min):** the AVM pattern module, `disable_local_auth = true`, and
   the Granite `managedComputeDeployments` resource. Granite takes a while to
   provision, so deploy it before the talk.
5. **AKS Automatic (3 min):** the `sku = "Automatic"` module call, the deferred
   `chat_api` component, the token exchange plugin and the constrained role delegation.
6. **It works (2 min):** `curl` the chat API, then show the service account
   annotation; no key exists anywhere.

## Notes

- **Region:** West US 3 (Phoenix) is the closest Azure region to Salt Lake City with
  availability zones, which AKS Automatic requires.
- **Model:** `var.model` in `components/foundry` defaults to
  `azureml://registries/azure-huggingface/models/ibm-granite--granite-4.2-30b/versions/1`
  with the single-A100 64k deployment template. Managed compute serves only the
  `azure-huggingface` registry; Granite 4.1 8B is not in it. List the options with
  `az ml model list --registry-name azure-huggingface` and read a model's
  `allowed_deployment_templates` with `az ml model show`; the model URI is immutable
  once deployed.
- **GPU quota:** managed compute has its own quota per accelerator family, separate
  from VM quota. Check it, and request more A100 quota if the limit is 0:

  ```sh
  az rest --method get --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.CognitiveServices/locations/westus3/managedComputeUsages?api-version=2026-09-15-preview"
  ```

- **Preview:** managed compute deployments are in preview (no SLA). Content filtering
  is not in the request path for them.
- **Bootstrap state** is local (`bootstrap/terraform.tfstate`, gitignored) and holds
  identifiers only. Keep it to update or destroy the bootstrap later.
- **Tearing down:** set `destroy = true` on the `westus3` deployment and apply, then
  destroy the bootstrap. Keeping the deployment block keeps its identity token in
  place for the destroy run.
- **Redeploying:** a destroyed Foundry account stays soft-deleted for 48 hours and
  keeps its name. Purge it with `az cognitiveservices account purge`, or taint
  `random_string.suffix` in the bootstrap to get new names.
- **Cost:** ACR uses the module default (Premium, zone redundant). Granite bills per
  GPU hour while the deployment exists, idle or not (about $3.95/hour for one A100 at
  launch pricing), and AKS Automatic bills while running. Destroy after the talk.
