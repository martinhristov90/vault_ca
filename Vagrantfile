Vagrant.configure("2") do |config|
    config.vm.box = "martinhristov90/vault"
    config.vm.box_download_insecure = true
    # PKIpass variable is passed to vaultUser script to provide password for pkiadmin user.
    config.vm.provision "shell", path: "./configs/scripts/vaultUser.sh", privileged: false, env: {"PKIpass" => "password"}
    # Provision PKI infrastructure
    config.vm.provision "shell", path: "./configs/scripts/vaultPKI.sh", privileged: true, env: {"PKIpass" => "password"}
  end
  