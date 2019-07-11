#!/usr/bin/env bash


# Setting Vault Address, it is running on localhost at port 8200
export VAULT_ADDR=http://127.0.0.1:8200
# Setting the Vault Address in Vagrant user bash profile
grep "VAULT_ADDR" ~/.bash_profile  > /dev/null 2>&1 || {
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bash_profile
}

echo "Check if Vault is already initialized..."
if [ `vault status -address=${VAULT_ADDR}| awk 'NR==4 {print $2}'` == "true" ]
then
    echo "Vault already initialized...exiting..."
    exit 1
fi


# Making working dir for Vault setup
mkdir -p /home/vagrant/_vaultSetup
touch /home/vagrant/_vaultSetup/keys.txt


echo "Setting up PKI admin user..."


echo "Initializing Vault..."
vault operator init -address=${VAULT_ADDR} > /home/vagrant/_vaultSetup/keys.txt
export VAULT_TOKEN=$(grep 'Initial Root Token:' /home/vagrant/_vaultSetup/keys.txt | awk '{print substr($NF, 1, length($NF))}')

echo "Unsealing vault..."
vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 1:' /home/vagrant/_vaultSetup/keys.txt | awk '{print $NF}') > /dev/null 2>&1
vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 2:' /home/vagrant/_vaultSetup/keys.txt | awk '{print $NF}') > /dev/null 2>&1
vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 3:' /home/vagrant/_vaultSetup/keys.txt | awk '{print $NF}') > /dev/null 2>&1

echo "Auth with root token..."
vault login -address=${VAULT_ADDR} token=${VAULT_TOKEN} > /dev/null 2>&1

## CREATE USER
echo "Create PKI admin ... change password if needed!!"

vault auth enable -address=${VAULT_ADDR} userpass > /dev/null 2>&1

vault policy write -address=${VAULT_ADDR} pkiadmin /vagrant/configs/policies/PKIadmin.hcl > /dev/null 2>&1

vault write -address=${VAULT_ADDR} auth/userpass/users/pkiadmin password=${PKIpass} policies=pkiadmin
