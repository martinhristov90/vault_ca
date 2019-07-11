## HashiCorp Vault CA

### Purpose :

- This repository purpose is to create Certification Authority by using HashiCorp Vault.

### Instructions :

- Use `git clone git@github.com:martinhristov90/vaultCA.git` to clone the project.
- For a start, a Vagrant box created with packer is going to be used. It can be found [here](https://github.com/martinhristov90/packerVault). The box comes with HashiCorp Vault server pre-installed, running as Systemd service, as well as simple configuration that listens on default port 8200 and uses `file` as storage backend.
- To setup the CA, user `pkiadmin` is going to be created and be given the policies defined in `configs/policies/PKIadmin.hcl`. The password of this user is set by using `PKIpass` environment variable in the projects `Vagrantfile`.
- When the provision finishes, a user named `pkiadmin` is created for you in Vault. This user is already logged-in in Vault, you can check that by doing `vagrant ssh` and then `vault token lookup`, you should see output like this :
    ```
    Key                 Value
    ---                 -----
    accessor            0pKcraYnBqJH2yO7t2NztKKI
    creation_time       1562846295
    creation_ttl        768h
    display_name        userpass-pkiadmin
    entity_id           fb4f6c42-2da1-c375-6a55-668d5b5656e2
    expire_time         2019-08-12T11:58:15.349629272Z
    explicit_max_ttl    0s
    id                  ----TOKEN----
    issue_time          2019-07-11T11:58:15.349628855Z
    meta                map[username:pkiadmin]
    num_uses            0
    orphan              true
    path                auth/userpass/login/pkiadmin
    policies            [default pkiadmin]
    renewable           true
    ttl                 767h31m16s
    type                service
    ```
- Note line `policies            [default pkiadmin]`, this line shows the associated policies with the `pkiadmin` user.



---- UNDER CONSTRUCTION ----


