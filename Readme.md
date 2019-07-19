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

### How to setup Vault to use the newly generated certificate for its UI.

- When the script `vaultPKI.sh`, it is going to place the generated certificates in `/etc/vault.d/certsUI/` folder.
- You can find a copy of Root CA certificate in your host machine project's directory, to be imported in your browser of choice.
- Log-in to the Vagrant box by using `vagrant ssh` in project's directory.
- Execute `sudo systemctl stop vault` to stop Vault.
- Edit the configuration file for Vault with `vi /etc/vault.d/vault.hcl`, to set the usage of certificates for the UI, it should look like this :
    ```
    backend "file" {
    path = "/vaultDataDir"
    }
    listener "tcp" {
    address = "0.0.0.0:8200"
    #tls_disable = 1
    tls_cert_file = "/etc/vault.d/certsUI/chainedCerts.pem"
    tls_key_file  = "/etc/vault.d/certsUI/certificatePrivate.pem"
    }

    # mlock() should be enabled 
    disable_mlock = false

    # Enable UI
    ui = true
    ```
- Execute `sudo systemctl start vault` to start Vault.
- Import the file `ca.pam` from project's directory to your OS keychain, and mark it as trusted. (This step is platform and browser dependable).
- Access `https://127.0.0.1:8200` from your host's machine browser, secure connection should be establised.
- If you try to execute any command using the Vault CLI you are going to get an error, in order to communicate with Vault secured connection needs to be establised, to do so execute:
    ```
    export VAULT_CACERT=/vagrant/ca.pem
    export VAULT_ADDR=https://localhost:8200 # (does not matter if you use 127.0.0.1 or localhost as address the certificate includes both)
    ```
#### Security Notes !

- Shares of the secret key for unsealing Vault and root token are saved to file `/home/vagrant/_vaultSetup/keys.txt` to be used for deployment process, take care of them.
- Keep in mind that `vagrant` user is logged in with `root` token during the deployment process, to log-out execute `rm ~/.vault-token`

#### Nota Bene !

- All provisioning scripts include comments per line, they can provide more information to you.