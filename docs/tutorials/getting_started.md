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
sudo snap install microk8s --channel=1.31-strict/stable
```

Add your user to the `microk8s` group:

```console
sudo usermod -a -G snap_microk8s $USER
newgrp snap_microk8s
```

Add the community repository MicroK8s addon:

```console
microk8s addons repo add community https://github.com/canonical/microk8s-community-addons --reference feat/strict-fix-multus
```

Enable the following MicroK8s addons. 
We must give MetalLB an address range that has at least 3 IP addresses for Charmed Aether SD-Core.

```console
sudo microk8s enable hostpath-storage
sudo microk8s enable multus
sudo microk8s enable metallb:10.0.0.2-10.0.0.4
```

### Bootstrap a Juju controller

From your terminal, install Juju:

```console
sudo snap install juju --channel=3.6/stable
```

Bootstrap a Juju controller:

```console
juju bootstrap microk8s
```

```{note}
There is a [bug](https://bugs.launchpad.net/juju/+bug/1988355) in Juju that occurs when
bootstrapping a controller on a new machine. If you encounter it, create the following
directory:
`mkdir -p /home/ubuntu/.local/share`
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
cat << EOF > core.tf
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

  model          = juju_model.sdcore.name
  depends_on     = [module.sdcore-router]

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
juju status --watch 1s --relations
```

The deployment is ready when all the charms are in the `active/idle` state.<br>
It is normal for `grafana-agent` and `traefik` to be in `blocked` state.<br>

Example:

```console
ubuntu@host:~/terraform $ juju status
Model   Controller          Cloud/Region        Version  SLA          Timestamp
sdcore  microk8s-localhost  microk8s/localhost  3.6.1    unsupported  11:35:07+02:00

App                       Version  Status   Scale  Charm                     Channel        Rev  Address         Exposed  Message
amf                       1.6.4    active       1  sdcore-amf-k8s            1.6/edge       908  10.152.183.217  no       
ausf                      1.6.2    active       1  sdcore-ausf-k8s           1.6/edge       713  10.152.183.19   no       
grafana-agent             0.40.4   blocked      1  grafana-agent-k8s         latest/stable  111  10.152.183.102  no       Missing ['grafana-cloud-config']|['logging-consumer'] for logging-provider; ['grafana-cloud-config']|['send-remote-wr...
mongodb                            active       1  mongodb-k8s               6/stable        61  10.152.183.18   no       
nms                       1.1.0    active       1  sdcore-nms-k8s            1.6/edge       849  10.152.183.42   no       
nrf                       1.6.2    active       1  sdcore-nrf-k8s            1.6/edge       790  10.152.183.234  no       
nssf                      1.6.1    active       1  sdcore-nssf-k8s           1.6/edge       669  10.152.183.40   no       
pcf                       1.6.1    active       1  sdcore-pcf-k8s            1.6/edge       710  10.152.183.129  no       
router                             active       1  sdcore-router-k8s         1.6/edge       464  10.152.183.176  no       
self-signed-certificates           active       1  self-signed-certificates  1/stable       263  10.152.183.71   no       
smf                       2.0.2    active       1  sdcore-smf-k8s            1.6/edge       801  10.152.183.81   no       
traefik                   2.11.0   blocked      1  traefik-k8s               latest/stable  234  10.152.183.244  no       "external_hostname" must be set while using routing mode "subdomain"
udm                       1.6.1    active       1  sdcore-udm-k8s            1.6/edge       664  10.152.183.241  no       
udr                       1.6.2    active       1  sdcore-udr-k8s            1.6/edge       645  10.152.183.96   no       
upf                       2.0.1    active       1  sdcore-upf-k8s            1.6/edge       767  10.152.183.173  no       

Unit                         Workload  Agent  Address       Ports  Message
amf/0*                       active    idle   10.1.194.206         
ausf/0*                      active    idle   10.1.194.235         
grafana-agent/0*             blocked   idle   10.1.194.208         Missing ['grafana-cloud-config']|['logging-consumer'] for logging-provider; ['grafana-cloud-config']|['send-remote-wr...
mongodb/0*                   active    idle   10.1.194.237         Primary
nms/0*                       active    idle   10.1.194.255         
nrf/0*                       active    idle   10.1.194.213         
nssf/0*                      active    idle   10.1.194.243         
pcf/0*                       active    idle   10.1.194.250         
router/0*                    active    idle   10.1.194.210         
self-signed-certificates/0*  active    idle   10.1.194.239         
smf/0*                       active    idle   10.1.194.202         
traefik/0*                   blocked   idle   10.1.194.230         "external_hostname" must be set while using routing mode "subdomain"
udm/0*                       active    idle   10.1.194.249         
udr/0*                       active    idle   10.1.194.245         
upf/0*                       active    idle   10.1.194.217         

Offer  Application  Charm           Rev  Connected  Endpoint        Interface       Role
amf    amf          sdcore-amf-k8s  908  0/0        fiveg-n2        fiveg_n2        provider
nms    nms          sdcore-nms-k8s  849  0/0        fiveg_core_gnb  fiveg_core_gnb  provider
upf    upf          sdcore-upf-k8s  767  0/0        fiveg_n3        fiveg_n3        provider
```

### Configure the ingress

Get the external IP address of Traefik's `traefik-lb` LoadBalancer service:

```console
microk8s.kubectl -n sdcore get svc | grep "traefik-lb"
```

The output should look similar to below:

```console
ubuntu@host:~/terraform $ microk8s.kubectl -n sdcore get svc | grep "traefik-lb"
traefik-lb                           LoadBalancer   10.152.183.83    10.0.0.2      80:30462/TCP,443:30163/TCP    9m4s
```

In this tutorial, the IP is `10.0.0.2`. Please note it, as we will need it in the next step.

Configure Traefik to use an external hostname. To do that, edit `traefik_config` in the `core.tf` file:

```
:caption: core.tf
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

## 2. Deploy Charmed OAI RAN CU and DU

Create a Terraform module for the Radio Access Network and add Charmed OAI RAN CU and Charmed OAI RAN DU to it:

```console
cat << EOF > ran.tf
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
    endpoint = module.du.requires.fiveg_f1
  }
  application {
    name     = module.cu.app_name
    endpoint = module.cu.provides.fiveg_f1
  }
}

EOF
```

Update Juju Terraform provider:

```console
terraform init
```

Deploy Charmed OAI RAN CU and DU:

```console
terraform apply -auto-approve
```

Monitor the status of the deployment:

```console
juju switch ran
juju status --watch 1s --relations
```

At this stage both the `cu` and the `du` applications are expected to be in the `waiting/idle` state and the messages should indicate they're waiting for network configuration.

Example:

```console
ubuntu@host:~/terraform $ juju status
Model  Controller          Cloud/Region        Version  SLA          Timestamp
ran    microk8s-localhost  microk8s/localhost  3.6.1    unsupported  11:43:43+02:00

SAAS  Status  Store  URL
amf   active  local  admin/sdcore.amf
nms   active  local  admin/sdcore.nms

App  Version  Status   Scale  Charm           Channel   Rev  Address         Exposed  Message
cu            waiting      1  oai-ran-cu-k8s  2.2/edge   63  10.152.183.220  no       Waiting for TAC and PLMNs configuration
du            waiting      1  oai-ran-du-k8s  2.2/edge   84  10.152.183.124  no       Waiting for F1 information

Unit   Workload  Agent  Address       Ports  Message
cu/0*  waiting   idle   10.1.194.194         Waiting for TAC and PLMNs configuration
du/0*  waiting   idle   10.1.194.196         Waiting for F1 information
```

## 3. Configure the 5G core network through the Network Management System

Retrieve the NMS credentials (`username` and `password`):

```console
juju switch sdcore
juju show-secret NMS_LOGIN --reveal
```

The output looks like this:

```
cvmg6h7mp25c7619i89g:
  revision: 2
  checksum: 68cb0ef846164496a7b4233933c339b667563b1ad93351f1a3e43ceec0dc3d39
  owner: nms
  label: NMS_LOGIN
  created: 2025-04-02T09:28:37Z
  updated: 2025-04-02T09:41:02Z
  content:
    password: 8lR4jyOKQQz
    token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDM1OTA0NjEsInVzZXJuYW1lIjoiY2hhcm0tYWRtaW4tRFhRVCIsInJvbGUiOjF9.OPd4zEjNqhxkptRrGeybfSqwU78epk2tz7o69zLQnq8
    username: charm-admin-DXQT
```

Retrieve the NMS address:

```console
juju run traefik/0 show-proxied-endpoints
```

The output should be `http://sdcore-nms.10.0.0.2.nip.io/`.<br>
Navigate to this address in your browser and use the `username` and `password` to login.

### Assign Tracking Area Code (TAC) to the gNodeB

In the Network Management System (NMS) navigate to the `Inventory` tab. Click the `Edit` button next to the integrated gNB name and set `TAC` to `1`:

```{image} ../images/getting_started_gnb_tac.png
:alt: NMS Inventory
:align: center
```

Confirm new `TAC` value by clicking the `Submit` button.

### Create a Network Slice

Navigate to the `Network slices` tab and create a network slice with the following attributes:

- Name: `default`
- MCC: `001`
- MNC: `01`
- UPF: `upf-external.sdcore.svc.cluster.local:8805`
- gNodeB: `ran-cu-cu (tac:1)`

You should see the following network slice created:

```{image} ../images/nms_network_slice.png
:alt: NMS Network Slice
:align: center
```

### Create a Device Group

Navigate to the `Device groups` tab and create a device group with the following attributes:

- Name: `device-group`
- Network Slice: `default`
- Subscriber IP pool: `172.250.1.0/16`
- DNS: `8.8.8.8`
- MTU (bytes): `1456`
- Maximum bitrate (Mbps):
  - Downstream: `200`
  - Upstream: `20`
- QoS:
  - 5QI: `1: GBR - Conversational Voice`
  - ARP: `6`

You should see the following device group created:

```{image} ../images/nms_device_group.png
:alt: NMS Device Group
:align: center
```

### Create a Subscriber

Navigate to `Subscribers` tab and click the `Create` button. Fill in the following:


- Network Slice: `default`
- Device Group: `device-group`

Click the two `Generate` buttons to automatically fill in the values in the form. Note the IMSI, OPC, Key and Sequence Number; we are going to use them shortly.

After clicking the `Submit` button you should see the subscriber created:

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

After adding the network configuration the CU and the DU should change their state to `active/idle`. 

To verify that run:

```console
juju switch ran
juju status
```

Output should be similar to:

```console
ubuntu@host:~/terraform $ juju status
Model  Controller          Cloud/Region        Version  SLA          Timestamp
ran    microk8s-localhost  microk8s/localhost  3.6.1    unsupported  09:29:04+01:00

SAAS  Status  Store  URL
amf   active  local  admin/sdcore.amf
nms   active  local  admin/sdcore.nms

App  Version  Status  Scale  Charm           Channel   Rev  Address         Exposed  Message
cu            active      1  oai-ran-cu-k8s  2.2/edge   55  10.152.183.152  no
du            active      1  oai-ran-du-k8s  2.2/edge   64  10.152.183.80   no

Unit   Workload  Agent  Address       Ports  Message
cu/0*  active    idle   10.1.194.205         
du/0*  active    idle   10.1.194.250
```

## 5. Deploy Charmed OAI RAN UE Simulator

Add Charmed OAI RAN UE Terraform module to `ran.tf`. Please replace the `imsi`, `key` and `opc` with the subscriber values from previous step:

```console
cat << EOF >> ran.tf
module "ue" {
  source = "git::https://github.com/canonical/oai-ran-ue-k8s-operator//terraform"

  model = juju_model.oai-ran.name

  config = {
    imsi = "001010100007487"                   # Use the IMSI generated in the previous step
    key  = "5122250214c33e723a5dd523fc145fc0"  # Use the Key generated in the previous step
    opc  = "981d464c7c52eb6e5036234984ad0bcf"  # Use the OPC generated in the previous step
  }
}

resource "juju_integration" "ue-du" {
  model = juju_model.oai-ran.name
  application {
    name     = module.ue.app_name
    endpoint = module.ue.requires.fiveg_rfsim
  }
  application {
    name     = module.du.app_name
    endpoint = module.du.provides.fiveg_rfsim
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
juju run ue/leader ping
```

The simulation executed successfully if you see `success: "true"` as one of the output messages:

```console
ubuntu@host:~$ juju run ue/leader ping
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
the `terraform` directory manually by removing everything except for the `core.tf`
and `terraform.tf` files.
```

Destroy the Juju controller and all its models:

```console
juju kill-controller microk8s-localhost
```
