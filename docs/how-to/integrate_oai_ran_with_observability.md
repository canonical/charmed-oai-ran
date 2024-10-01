# Integrate Charmed OAI RAN with Canonical Observability Stack

[Charmed OAI RAN Terraform modules][Charmed OAI RAN Terraform modules] come with built-in support for the Canonical Observability Stack (COS).
By default, COS deployment and integration is disabled.

Each Charmed OAI RAN module exposes a set of configuration variables for deploying and integrating COS.

This guide covers three ways of integrating Charmed OAI RAN with COS:
1. [Integrating Charmed OAI RAN with COS at the deployment stage](#option-1)
2. [Adding COS to an existing Charmed OAI RAN deployment](#option-2)
3. [Integrating Charmed OAI RAN with an existing COS deployment](#option-3)

```{note}
Deploying Canonical Observability Stack will increase the resources consumption on the K8s cluster. 
Make sure your Kubernetes cluster is capable of handling the load from both Charmed OAI RAN and COS before proceeding.  
```

(option-1)=
## Integrating Charmed OAI RAN with COS at the deployment stage

This option allows deploying COS and integrating it with Charmed OAI RAN as a Day 1 operation.

To deploy and integrate COS together with a chosen Charmed OAI RAN subsystem, set the following configuration variables in your TF module file:

```console
deploy_cos     = true
cos_model_name = "YOUR_CUSTOM_COS_MODEL_NAME" (Optional. Defaults to `cos-lite`.)
```

Example:

```console
cat << EOF > main.tf
module "oai-ran" {
  source = "git::https://github.com/canonical/terraform-juju-oai-ran//modules/oai-ran-k8s"
  (...)
  deploy_cos     = true
  cos_model_name = "my-cos"
  (...)
}

EOF
```

Apply the changes:

```console
terraform apply -auto-approve
```

(option-2)=
## Adding COS to an existing Charmed OAI RAN deployment

This option allows deploying COS and integrating it with the existing Charmed OAI RAN deployment (a Day 2 operation).

To deploy and integrate COS with the existing Charmed OAI RAN deployment edit the TF module file used to deploy a chosen Charmed OAI RAN subsystem and add the following configuration variables:

```console
deploy_cos     = true
cos_model_name = "YOUR_CUSTOM_COS_MODEL_NAME" (Optional. Defaults to `cos-lite`.)
```

Example:

```console
vim my-deployment-module.tf
```

```console
(...)
module "oai-ran-cu" {
  source = "git::https://github.com/canonical/terraform-juju-oai-ran//modules/oai-ran-cu-k8s"
  (...)
  deploy_cos     = true
  cos_model_name = "my-cos"
  (...)
}
(...)
```

Apply the changes:

```console
terraform apply -auto-approve
```

(option-3)=
## Integrating Charmed OAI RAN with an existing COS deployment

This option allows integrating Charmed OAI RAN with an existing COS deployment. It can be used as both Day 1 and Day 2 operation.

```{note}
To use this option following conditions need to be met:
- Canonical Observability Stack deployed to a Juju model
- Prometheus's `remote-write` cross-model integration offer created
- Loki's `logging` cross-model integration offer created
```

To integrate a chosen Charmed OAI RAN subsystem with an existing COS deployment, set the following configuration variables in your TF module file:

```console
use_existing_cos                  = true
cos_model_name                    = "YOUR_CUSTOM_COS_MODEL_NAME" (Optional. Defaults to `cos-lite`.)
prometheus_remote_write_offer_url = "CROSS_MODEL_INTEGRATION_OFFER_URL" (The URL is typicall formatter as follows: [<controller name>:][<model owner>/]<model name>.<application name>)
loki_logging_offer_url            = "CROSS_MODEL_INTEGRATION_OFFER_URL" (The URL is typicall formatter as follows: [<controller name>:][<model owner>/]<model name>.<application name>)
```

Example:

```console
module "oai-ran-du" {
  source = "git::https://github.com/canonical/terraform-juju-oai-ran//modules/oai-ran-du-k8s"
  (...)
  use_existing_cos                  = true
  cos_model_name                    = "my-existing-cos"
  prometheus_remote_write_offer_url = "admin/my-existing-cos.prometheus"
  loki_logging_offer_url            = "admin/my-existing-cos.loki"
  (...)
}
```

Apply the changes:

```console
terraform apply -auto-approve
```

[Charmed OAI RAN Terraform modules]: https://github.com/canonical/terraform-juju-oai-ran-k8s
