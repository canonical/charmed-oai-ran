# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_model" "oai-ran" {
  name = "ran"
}

module "cu" {
  source = "git::https://github.com/canonical/oai-ran-cu-k8s-operator//terraform"

  model  = juju_model.oai-ran.name
  config = {
    "n3-interface-name": "ran"
  }
}

module "du" {
  source = "git::https://github.com/canonical/oai-ran-du-k8s-operator//terraform"

  model  = juju_model.oai-ran.name
  config = {
    "simulation-mode": true,
    "bandwidth": 40,
    "frequency-band": 77,
    "sub-carrier-spacing": 30,
    "center-frequency": "4060",
  }
}

resource "juju_integration" "cu-amf" {
  model = juju_model.oai-ran.name
  application {
    name     = module.cu.app_name
    endpoint = module.cu.requires.fiveg_n2
  }
  application {
    offer_url = module.sdcore.amf_fiveg_n2_offer_url
  }
}

resource "juju_integration" "cu-nms" {
  model = juju_model.oai-ran.name
  application {
    name     = module.cu.app_name
    endpoint = module.cu.requires.fiveg_core_gnb
  }
  application {
    offer_url = module.sdcore.nms_fiveg_core_gnb_offer_url
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

module "ue" {
  source = "git::https://github.com/canonical/oai-ran-ue-k8s-operator//terraform"

  model = juju_model.oai-ran.name
  config = {
    "simulation-mode": true,
  }
}

resource "juju_integration" "ue-du" {
  model = juju_model.oai-ran.name
  application {
    name     = module.ue.app_name
    endpoint = module.ue.requires.fiveg_rf_config
  }
  application {
    name     = module.du.app_name
    endpoint = module.du.provides.fiveg_rf_config
  }
}
