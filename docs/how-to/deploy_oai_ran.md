# Deploy Charmed OAI RAN

This guide explains how to deploy the Charmed OAI RAN CU and DU applications using Terraform.

## 1. Create a Terraform module for the Radio Access Network

Create a Terraform module for the Radio Access Network and add Charmed OAI RAN CU and Charmed OAI RAN DU to it:

```console
cat << EOF > ran.tf
resource "juju_model" "oai-ran" {
  name = "ran"
}

module "cu" {
  source = "git::https://github.com/canonical/oai-ran-cu-k8s-operator//terraform"

  model_name = juju_model.oai-ran.name
  config     = {
    "n3-interface-name": "ran"
  }
}

module "du" {
  source = "git::https://github.com/canonical/oai-ran-du-k8s-operator//terraform"

  model_name = juju_model.oai-ran.name
  config     = {
    "simulation-mode": false,
    "use-three-quarter-sampling": true
  }
}

resource "juju_integration" "cu-amf" {
  model = juju_model.oai-ran.name
  application {
    name     = module.cu.app_name
    endpoint = module.cu.fiveg_n2_endpoint
  }
  application {
    offer_url = module.sdcore.amf_fiveg_n2_offer_url  // Offer URL from the AMF charm
  }
}

resource "juju_integration" "cu-nms" {
  model = juju_model.oai-ran.name
  application {
    name     = module.cu.app_name
    endpoint = module.cu.fiveg_core_gnb_endpoint
  }
  application {
    offer_url = module.sdcore.nms_fiveg_core_gnb_offer_url    // Offer URL from the NMS charm
  }
}

resource "juju_integration" "du-cu" {
  model = juju_model.oai-ran.name
  application {
    name     = module.du.app_name
    endpoint = module.du.fiveg_f1_endpoint
  }
  application {
    name     = module.cu.app_name
    endpoint = module.cu.fiveg_f1_endpoint
  }
}

EOF
```

```{note}
The instruction above assumes that the OAI RAN will be integrated to Charmed Aether SD-Core. If you use a different 5G core network, you will need to change the AMF and NMS offer URLs.
```

## 2. Update Juju Terraform provider

```console
terraform init
```

## 3. Deploy Charmed OAI RAN

```console
terraform apply -auto-approve
```

## 4. Monitor the status of the deployment

```console
juju switch ran
juju status --watch 1s --relations
```

At this stage both the `cu` and the `du` applications are expected to be in the `waiting/idle` state and the messages should indicate they're waiting for network configuration. The charms will go to `active/idle` state once network configuration information necessary to start the workloads is provided to the charms through the `fiveg_core_gnb` (between the Core and the CU) and `fiveg_f1` (between the CU and DU) Juju integrations. This information is automatically exchanged when the charms are integrated with Charmed Aether SD-Core.
