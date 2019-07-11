### HashiCorp Vault CA

### Purpose :

- This repository purpose is to create Certification Authority by using HashiCorp Vault.

### Instructions :

- For a start, a Vagrant box created with packer is going to be used. It can be found [here](https://github.com/martinhristov90/packerVault). The box comes with HashiCorp Vault server pre-installed, running as Systemd service, as well as simple configuration that listens on default port 8200 and uses `file` as storage backend.
- To setup the CA, user `pkiadmin` is going to be created and be given the policies defined in `configs/policies/PKIadmin.hcl`. The password of this user is set by using `PKIpass` environment variable in the projects `Vagrantfile`



---- UNDER CONSTRUCTION ----


