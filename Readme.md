## HashiCorp Vault CA

### Purpose :

- This repository purpose is to create Certification Authority by using HashiCorp Vault.

### Instructions :

- Use `git clone git@github.com:martinhristov90/vaultCA.git` to clone the project.
- For a start, a Vagrant box created with packer is going to be used. It can be found [here](https://github.com/martinhristov90/packerVault). The box comes with HashiCorp Vault server pre-installed, running as Systemd service, as well as simple configuration that listens on default port 8200 and uses `file` as storage backend.

### What tasks`configs/scripts/vaultUser.sh` script performs:

- To setup the CA, user `pkiadmin` is going to be created and be given the policies defined in `configs/policies/PKIadmin.hcl`, they are permissive enough to perform day-to-day operation on PKI. 
- The password of this user is set by using `PKIpass` environment variable in the projects `Vagrantfile`.
- When the provision finishes, a user named `pkiadmin` is created for you in Vault. You can log-in to the vagrant box using `vagrant ssh` and log-in as `pkiadmin` user by using `vault login -method=userpass username=pkiadmin` and then enter the password you have set, the output should look like this:
    ```
    Key                    Value
    ---                    -----
    token                  ---TOKEN---
    token_accessor         ---ACCESSOR---
    token_duration         768h
    token_renewable        true
    token_policies         ["default"]
    identity_policies      ["pkiadminpolicy"]
    policies               ["default" "pkiadminpolicy"]
    token_meta_username    pkiadmin
    ```
- Note the line `policies ["default" "pkiadminpolicy"]`, this line shows the associated policies with the `pkiadmin` user at the moment. This policy is permissive enough to operate and administer PKI infrastructure and to enable or disable PKI secret backend, you can review it in `config/policies/PKIadmin.hcl`.

### What tasks`configs/scripts/vaultPKI.sh` script performs:

- Uses the `pkiadmin` user created by `vaultUser.sh` scripts, it uses `pkiadminpolicy` to provision the PKI infrastructure.
- Creates root CA and intermediate CA.
- Sets root CA and intermediate CA, issuing_ca URL and CRL URL.
- Issues certificate to be used for Vault UI.

---- UNDER CONSTRUCTION ----


