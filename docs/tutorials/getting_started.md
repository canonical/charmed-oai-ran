# Getting started

In this tutorial, we will deploy and run Charmed OAI RAN (Radio Access Network) using Juju and Terraform.
The Charmed OAI RAN consists of two Juju charms representing the CU (Central Unit) and the DU (Distributed Unit).

As part of this tutorial, we will also deploy additional components:

- Charmed Aether SD-Core: A 5G core network which will manage our RAN network
- SD-Core Router: a software router facilitating communication between the 5G Core and the RAN
- User Equipment (UE) simulator: A simulated cellphone which will allow us to validate the correctness of the entire deployment

To complete this tutorial, you will need a machine which meets the following requirements:

- A recent `x86_64` CPU (Intel 4ᵗʰ generation or newer, or AMD Ryzen or newer)
- At least 4 cores (8 recommended)
- At least 8 GB of RAM (16 GB recommended)
- 50GB of free disk space

## 1. Deploy Charmed Aether SD-Core

### Install MicroK8s

From your terminal, install MicroK8s:

```console
sudo snap install microk8s --channel=1.29/stable --classic
```

Add your user to the `microk8s` group:

```console
sudo usermod -a -G microk8s $USER
newgrp microk8s
```

Add the community repository MicroK8s addon:

```console
microk8s addons repo add community https://github.com/canonical/microk8s-community-addons --reference feat/strict-fix-multus
```

Enable the following MicroK8s addons. 
We must give MetalLB an address range that has at least 3 IP addresses for Charmed Aether SD-Core.

```console
microk8s enable hostpath-storage
microk8s enable multus
microk8s enable metallb:10.0.0.2-10.0.0.4
```

Export MicroK8s cluster's configuration:

```console
microk8s config > ~/.kube/config
```

### Bootstrap a Juju controller

From your terminal, install Juju:

```console
sudo snap install juju --channel=3.4/stable
```

Add MicroK8s cluster to Juju:

```console
juju add-k8s microk8s-classic
```

Bootstrap a Juju controller:

```console
juju bootstrap microk8s-classic
```

### Install Terraform

From your terminal, install Terraform:

```console
sudo snap install terraform --classic
```

### Create Terraform module

On the host machine create a new directory called `terraform`:

```console
mkdir terraform
```

Inside newly created `terraform` directory create a `terraform.tf` file:

```console
cd terraform
cat << EOF > versions.tf
terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = ">= 0.12.0"
    }
  }
}
EOF
```

Create a Terraform module containing the Charmed Aether SD-Core and a router:

```console
cat << EOF > main.tf
resource "juju_model" "sdcore" {
  name = "sdcore"
}

module "sdcore-router" {
  source = "git::https://github.com/canonical/sdcore-router-k8s-operator//terraform"

  model      = juju_model.sdcore.name
  depends_on = [juju_model.sdcore]
}

module "sdcore" {
  source = "git::https://github.com/canonical/terraform-juju-sdcore//modules/sdcore-k8s"

  model        = juju_model.sdcore.name
  depends_on = [module.sdcore-router]

  traefik_config = {
    routing_mode = "subdomain"
  }
}

EOF
```

```{note}
You can get a ready example by cloning [this Git repository](https://github.com/canonical/charmed-oai-ran).
All necessary files are in the `examples/terraform/getting_started` directory.
```

### Deploy 5G Core network

Initialize Juju Terraform provider:

```console
terraform init
```

Deploy SD-Core by applying your Terraform configuration:

```console
terraform apply -auto-approve
```

The deployment process should take approximately 10-15 minutes.

Monitor the status of the deployment:

```console
juju switch sdcore
watch -n 1 -c juju status --color --relations
```

The deployment is ready when all the charms are in the `active/idle` state.<br>
It is normal for `grafana-agent` to remain in waiting state.<br>
It is also expected that `traefik` goes to the error state (related Traefik [bug](https://github.com/canonical/traefik-k8s-operator/issues/361)).

Example:

```console
ubuntu@host:~$ juju status
Model      Controller                  Cloud/Region                Version  SLA          Timestamp
sdcore     microk8s-classic-localhost  microk8s-classic/localhost  3.4.5    unsupported  08:08:50Z

App                       Version  Status   Scale  Charm                     Channel        Rev  Address         Exposed  Message
amf                       1.4.4    active       1  sdcore-amf-k8s            1.5/edge       707  10.152.183.176  no       
ausf                      1.4.2    active       1  sdcore-ausf-k8s           1.5/edge       520  10.152.183.65   no       
grafana-agent             0.32.1   waiting      1  grafana-agent-k8s         latest/stable   45  10.152.183.221  no       installing agent
mongodb                            active       1  mongodb-k8s               6/beta          38  10.152.183.92   no       Primary
nms                       1.0.0    active       1  sdcore-nms-k8s            1.5/edge       580  10.152.183.141  no       
nrf                       1.4.1    active       1  sdcore-nrf-k8s            1.5/edge       580  10.152.183.130  no       
nssf                      1.4.1    active       1  sdcore-nssf-k8s           1.5/edge       462  10.152.183.62   no       
pcf                       1.4.3    active       1  sdcore-pcf-k8s            1.5/edge       512  10.152.183.144  no       
router                             active       1  sdcore-router-k8s         1.5/edge       341  10.152.183.218  no       
self-signed-certificates           active       1  self-signed-certificates  latest/stable  155  10.152.183.33   no       
smf                       1.5.2    active       1  sdcore-smf-k8s            1.5/edge       590  10.152.183.64   no       
traefik                   v2.11.0  waiting      1  traefik-k8s               latest/stable  194  10.152.183.198  no       installing agent
udm                       1.4.3    active       1  sdcore-udm-k8s            1.5/edge       489  10.152.183.31   no       
udr                       1.4.1    active       1  sdcore-udr-k8s            1.5/edge       486  10.152.183.82   no       
upf                       1.4.0    active       1  sdcore-upf-k8s            1.5/edge       591  10.152.183.164  no       

Unit                         Workload  Agent  Address      Ports  Message
amf/0*                       active    idle   10.1.10.181         
ausf/0*                      active    idle   10.1.10.186         
grafana-agent/0*             blocked   idle   10.1.10.133         grafana-cloud-config: off, logging-consumer: off
mongodb/0*                   active    idle   10.1.10.155         Primary
nms/0*                       active    idle   10.1.10.174         
nrf/0*                       active    idle   10.1.10.151         
nssf/0*                      active    idle   10.1.10.136         
pcf/0*                       active    idle   10.1.10.146         
router/0*                    active    idle   10.1.10.145         
self-signed-certificates/0*  active    idle   10.1.10.141         
smf/0*                       active    idle   10.1.10.154         
traefik/0*                   error     idle   10.1.10.160         hook failed: "ingress-relation-changed"
udm/0*                       active    idle   10.1.10.187         
udr/0*                       active    idle   10.1.10.176         
upf/0*                       active    idle   10.1.10.169
```

### Configure the ingress

Get the external IP address of Traefik's `traefik-lb` LoadBalancer service:

```console
microk8s.kubectl -n sdcore get svc | grep "traefik-lb"
```

The output should look similar to below:

```console
ubuntu@host:~/terraform$ microk8s.kubectl -n sdcore get svc | grep "traefik-lb"
traefik-lb                           LoadBalancer   10.152.183.142   10.0.0.2      80:32435/TCP,443:32483/TCP    11m
```

In this tutorial, the IP is `10.0.0.2`. Please note it, as we will need it in the next step.

Configure Traefik to use an external hostname. To do that, edit `traefik_config` in the `main.tf` file:

```
:caption: main.tf
(...)
module "sdcore" {
  (...)
  traefik_config = {
    routing_mode      = "subdomain"
    external_hostname = "10.0.0.2.nip.io"
  }
  (...)
}
(...)
```

Apply new configuration:

```console
terraform apply -auto-approve
```

Resolve Traefik error in Juju:

```console
juju resolve traefik/0
```

## 2. Deploy Charmed OAI RAN CU

Create a Terraform module for the Radio Access Network and add Charmed OAI RAN CU to it:

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

resource "juju_offer" "cu-fiveg-gnb-identity" {
  model            = juju_model.oai-ran.name
  application_name = module.cu.app_name
  endpoint         = module.cu.fiveg_gnb_identity_endpoint
}

resource "juju_integration" "cu-amf" {
  model = juju_model.oai-ran.name
  application {
    name     = module.cu.app_name
    endpoint = module.cu.fiveg_n2_endpoint
  }
  application {
    offer_url = module.sdcore.amf_fiveg_n2_offer_url
  }
}

resource "juju_integration" "cu-nms" {
  model = juju_model.sdcore.name
  application {
    name     = module.sdcore.nms_app_name
    endpoint = module.sdcore.fiveg_gnb_identity_endpoint
  }
  application {
    offer_url = juju_offer.cu-fiveg-gnb-identity.url
  }
}

EOF
```

Update Juju Terraform provider:

```console
terraform init
```

Deploy CU:

```console
terraform apply -auto-approve
```

Monitor the status of the deployment:

```console
juju switch ran
juju status --watch 1s --relations
```

The deployment is ready when the `cu` application is in the `active/idle` state.

## 3. Configure the 5G core network through the Network Management System

Retrieve the NMS address:

```console
juju switch sdcore
juju run traefik/0 show-proxied-endpoints
```

The output should be `http://sdcore-nms.10.0.0.2.nip.io/`.<br>
Navigate to this address in your browser.

In the Network Management System (NMS), create a network slice with the following attributes:

- Name: `Tutorial`
- MCC: `001`
- MNC: `01`
- UPF: `upf-external.private5g.svc.cluster.local:8805`
- gNodeB: `private5g-cu-cu (tac:1)`

You should see the following network slice created:

```{image} ../images/nms_network_slice.png
:alt: NMS Network Slice
:align: center
```

Navigate to Subscribers and create a new subscriber with the following attributes:

- IMSI: `001010100007487`
- OPC: `981d464c7c52eb6e5036234984ad0bcf`
- Key: `5122250214c33e723a5dd523fc145fc0`
- Sequence Number: `16f3b3f70fc2`
- Network Slice: `Tutorial`
- Device Group: `Tutorial-default`

You should see the following subscriber created:

```{image} ../images/nms_subscriber.png
:alt: NMS Subscriber
:align: center
```

```{note}
Due to current limitations in the network configuration procedure, it is required to restart the CU Pod after configuring the network.
This limitation will be addressed in the future.
To restart the CU Pod execute:
`microk8s.kubectl -n ran delete pod cu-0`
```

## 4. Deploy Charmed OAI RAN DU

Add Charmed OAI RAN DU Terraform module to `ran.tf`:

```console
cat << EOF >> ran.tf
module "du" {
  source = "git::https://github.com/canonical/oai-ran-du-k8s-operator//terraform"

  model_name = juju_model.oai-ran.name
  config     = {
    "simulation-mode": true
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

Update Juju Terraform provider:

```console
terraform init
```

Deploy DU:

```console
terraform apply -auto-approve
```

Monitor the status of the deployment:

```console
juju switch ran
juju status --watch 1s --relations
```

The deployment is ready when the `du` application is in the `active/idle` state.

## 5. Deploy Charmed OAI RAN UE Simulator

Add Charmed OAI RAN UE Terraform module to `ran.tf`:

```console
cat << EOF >> ran.tf
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

## 6. Run 5G network traffic simulation

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

## 7. Destroy the environment

Destroy Terraform deployment:

```console
terraform destroy -auto-approve
```

```{note}
Terraform does not remove anything from the working directory. If needed, please clean up
the `terraform` directory manually by removing everything except for the `main.tf`
and `terraform.tf` files.
```

Destroy the Juju controller and all its models:

```console
juju kill-controller microk8s-classic-localhost
```
