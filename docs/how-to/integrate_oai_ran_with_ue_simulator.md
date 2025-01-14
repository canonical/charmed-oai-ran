# Integrate Charmed OAI RAN with the OAI RAN UE Simulator

Charmed OAI RAN includes a UE simulator that can be used to simulate 5G network traffic and validate the RAN deployment.

This guide walks you through deploying the Charmed OAI RAN UE Simulator on a Kubernetes cluster using Juju and Terraform.

## 1. Configure Charmed OAI RAN DU to run in simulation mode

Charmed OAI RAN DU needs to be configured in simulation mode to work with the UE simulator.

To enable the DU to run in simulation mode, set the `simulation-mode` configuration option to `true`:

```hcl
module "du" {
  source = "git::https://github.com/canonical/oai-ran-du-k8s-operator//terraform"

  model_name = juju_model.oai-ran.name
  config     = {
    "simulation-mode": true
    "use-three-quarter-sampling" = "true"
  }
}
```

## 2. Deploy Charmed OAI RAN UE Simulator

In the same directory where you have the Charmed OAI RAN CU and DU Terraform modules, create a new Terraform module for the UE simulator:

```console
cat << EOF >> ue.tf
module "ue" {
  source = "git::https://github.com/canonical/oai-ran-ue-k8s-operator//terraform"

  model_name = juju_model.oai-ran.name
}

resource "juju_integration" "ue-du" {
  model = juju_model.oai-ran.name
  application {
    name     = module.ue.app_name
    endpoint = module.ue.fiveg_rfsim_endpoint
  }
  application {
    name     = module.du.app_name
    endpoint = module.du.fiveg_rfsim_endpoint
  }
}

EOF
```

Update Juju Terraform provider:

```console
terraform init
```

Deploy the UE simulator:

```console
terraform apply -auto-approve
```

Monitor the status of the deployment:

```console
juju status --watch 1s --relations
```

The deployment is ready when the `ue` application is in the `active/idle` state.

## 3. Run 5G network traffic simulation

Run the simulation:

```console
juju run ue/leader start-simulation
```

The simulation executed successfully if you see `success: "true"` as one of the output messages:

```console
ubuntu@host:~$ juju run ue/leader start-simulation
Running operation 1 with 1 task
  - task 2 on unit-ue-0

Waiting for task 2...
result: |
  PING 8.8.8.8 (8.8.8.8) from 172.250.0.2 oaitun_ue1: 56(84) bytes of data.
  64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=13.2 ms
  64 bytes from 8.8.8.8: icmp_seq=2 ttl=116 time=15.3 ms
  64 bytes from 8.8.8.8: icmp_seq=3 ttl=116 time=13.8 ms
  64 bytes from 8.8.8.8: icmp_seq=4 ttl=116 time=12.6 ms
  64 bytes from 8.8.8.8: icmp_seq=5 ttl=116 time=14.1 ms
  64 bytes from 8.8.8.8: icmp_seq=6 ttl=116 time=14.8 ms
  64 bytes from 8.8.8.8: icmp_seq=7 ttl=116 time=14.6 ms
  64 bytes from 8.8.8.8: icmp_seq=8 ttl=116 time=14.6 ms
  64 bytes from 8.8.8.8: icmp_seq=9 ttl=116 time=14.6 ms
  64 bytes from 8.8.8.8: icmp_seq=10 ttl=116 time=14.5 ms

  --- 8.8.8.8 ping statistics ---
  10 packets transmitted, 10 received, 0% packet loss, time 9010ms
  rtt min/avg/max/mdev = 12.561/14.217/15.294/0.772 ms
success: "true"
```
