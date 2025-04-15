# Security

## Secure Dependencies

### For the workload Container Images

Each workload in Charmed OAI RAN is distributed by Canonical as a rock container image. These images are built using [Rockcraft]( https://documentation.ubuntu.com/rockcraft/en/latest/), a tool to build secure, stable, and OCI-compliant container images.

Each container image is scanned for vulnerabilities and built on a weekly schedule. This means that the images are always up-to-date with the latest security patches and bug fixes.

### For the Charms

All libraries and dependencies utilized in Juju charms are also continuously monitored, scanned, and updated.
