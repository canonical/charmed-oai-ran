# Hardening

This section explains how to harden Charmed OAI RAN by securing communication with firewalls and VPNs and enhancing operations through observability.

## Infrastructure Hardening

1. Deploy Charmed OAI RAN behind a firewall:

   a. Allow only inbound traffic to required ports for the 5G RAN.

         - 2152 (UDP) for GTP-U traffic from the UPF to the CU

   b. Enable only outgoing traffic necessary for communication with trusted endpoints like the Core network.
        
        - 38412 (SCTP) for the SCTP traffic from the CU to the AMF

2. Secure communication between the CU and UPF.

  The GTP-U communication between the CU and UPF is sensitive and should be protected. It is recommended that this communication occurs over a secured local network or a VPN.

## Operational Hardening

1. Integrate with the Canonical Observability Stack (see the [integration guide](../how-to/integrate_oai_ran_with_observability.md)).
