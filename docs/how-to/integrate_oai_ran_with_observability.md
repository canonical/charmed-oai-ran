# Integrate Charmed OAI RAN with Canonical Observability Stack

One of the key aspects considered while developing Charmed OAI RAN was making it easily observable.
To achieve this, each [Charmed OAI RAN Terraform module][Charmed OAI RAN Terraform modules] includes Grafana Agent application, which allows for integration with the Canonical Observability Stack (COS).

This how-to guide outlines the process of integrating Charmed OAI RAN with COS.

Steps described in this guide can be performed as both Day 1 and Day 2 operations.

```{note}
Deploying Canonical Observability Stack will increase the resources consumption on the K8s cluster. 
Make sure your Kubernetes cluster is capable of handling the load from both Charmed OAI RAN and COS before proceeding.  
```

## 1. Add COS to the solution Terraform module

Update your solution Terraform module (here it's named `main.tf`):

```console
cat << EOF > main.tf
module "cos" {
  source                   = "git::https://github.com/canonical/terraform-juju-sdcore//modules/external/cos-lite"
  model_name               = "cos-lite"
  deploy_cos_configuration = true
  cos_configuration_config = {
    git_repo                = "https://github.com/canonical/sdcore-cos-configuration"
    git_branch              = "main"
    grafana_dashboards_path = "grafana_dashboards/sdcore/"
  }
}

resource "juju_integration" "prometheus-remote-write" {
  model = "YOUR_CHARMED_OAI_RAN_MODEL_NAME"

  application {
    name     = module.oai-ran.grafana_agent_app_name
    endpoint = module.oai-ran.send_remote_write_endpoint
  }

  application {
    offer_url = module.cos.prometheus_remote_write_offer_url
  }
}

resource "juju_integration" "loki-logging" {
  model = "YOUR_CHARMED_OAI_RAN_MODEL_NAME"

  application {
    name     = module.oai-ran.grafana_agent_app_name
    endpoint = module.oai-ran.logging_consumer_endpoint
  }

  application {
    offer_url = module.cos.loki_logging_offer_url
  }
}

EOF
```

```{note}
In this guide it is assumed, that the Terraform module responsible for deploying Charmed OAI RAN is named `oai-ran`.
If you use different name, please make sure it's reflected in COS integrations.
```

## 2. Apply the changes

Fetch COS module:

```console
terraform init
```

Apply new configuration:

```console
terraform apply -auto-approve
```

## 3. Example of a complete solution Terraform module including Charmed OAI RAN integrated with COS

```console
resource "juju_model" "ran" {
  name  = "charmed-oai-ran"
}

module "oai-ran" {
  source                   = "git::https://github.com/canonical/terraform-juju-oai-ran-k8s//modules/oai-ran-k8s"
  model_name               = juju_model.ran.name
  create_model             = false
}

module "cos" {
  source                   = "git::https://github.com/canonical/terraform-juju-sdcore//modules/external/cos-lite"
  model_name               = "cos-lite"
  deploy_cos_configuration = true
  cos_configuration_config = {
    git_repo                = "https://github.com/canonical/sdcore-cos-configuration"
    git_branch              = "main"
    grafana_dashboards_path = "grafana_dashboards/sdcore/"
  }
}

resource "juju_integration" "prometheus-remote-write" {
  model = juju_model.ran.name

  application {
    name     = module.oai-ran.grafana_agent_app_name
    endpoint = module.oai-ran.send_remote_write_endpoint
  }

  application {
    offer_url = module.cos.prometheus_remote_write_offer_url
  }
}

resource "juju_integration" "loki-logging" {
  model = juju_model.ran.name

  application {
    name     = module.oai-ran.grafana_agent_app_name
    endpoint = module.oai-ran.logging_consumer_endpoint
  }

  application {
    offer_url = module.cos.loki_logging_offer_url
  }
}
```

[Charmed OAI RAN Terraform modules]: https://github.com/canonical/terraform-juju-oai-ran-k8s
