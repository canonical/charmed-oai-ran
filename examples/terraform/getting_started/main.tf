# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_model" "private5g" {
  name = "private5g"
}

module "sdcore-router" {
  source = "git::https://github.com/canonical/sdcore-router-k8s-operator//terraform"

  model_name = juju_model.private5g.name
  depends_on = [juju_model.private5g]
}

module "sdcore" {
  source = "git::https://github.com/canonical/terraform-juju-sdcore//modules/sdcore-k8s"

  model_name = juju_model.private5g.name
  create_model = false

  traefik_config = {
    routing_mode      = "subdomain"
    external_hostname = "10.0.0.3.nip.io"
  }

  depends_on = [module.sdcore-router]
}
