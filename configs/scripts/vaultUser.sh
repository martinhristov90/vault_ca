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
    echo "Vault already initialized...Exiting..."
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

# Enabling userpass auth method.
vault auth enable -address=${VAULT_ADDR} userpass > /dev/null 2>&1

# Writing the PKIadmin policy.
vault policy write -address=${VAULT_ADDR} pkiadminpolicy /vagrant/configs/policies/PKIadmin.hcl > /dev/null 2>&1

# Creating pkiadmin user and attaching the pkiadmin policy to it.
#vault write -address=${VAULT_ADDR} auth/userpass/users/pkiadmin password=${PKIpass} policies=pkiadmin > /dev/null 2>&1
vault write -address=${VAULT_ADDR} auth/userpass/users/pkiadmin password=${PKIpass} > /dev/null 2>&1

# Creating identity, entity and entity-alias for user pkiadmin.
# This gets interesting if the user has two or more identites in different auth backends, for example userpass and github, they can be reladed to same identity entity.
# It alse pkiadmin user from github and pkiadmin from userpass auth backend to have same policies, pretty cool.

# Getting the accessor for userpass auth backend and saving it to a file to be used later.
echo "Getting accessor of userpass auth..."
vault auth list -format=json | jq -r '."userpass/".accessor' > _vaultSetup/accessorUserPass.txt

# Creating identity entity for pkiadmin user and attaching the "pkiadmin" policy to it.
echo "Creating identity entity (pkiAdminEntity) for user pkiadmin..."
vault write -format=json identity/entity name=pkiAdminEntity | jq -r .data.id > _vaultSetup/pkiAdminEntityID.txt

# Creating alias, it is used to map an entity to user in particular auth backend, the key point here is "name=" it should match the name of the user inside the particular auth backend.
echo "Creating entity-alias for pkiAdminEntity to refer to pkiadmnin user... "
vault write identity/entity-alias name=pkiadmin mount_accessor=`cat /home/vagrant/_vaultSetup/accessorUserPass.txt` canonical_id=`cat /home/vagrant/_vaultSetup/pkiAdminEntityID.txt` > /dev/null 2>&1

# Group creation and adding pkiAdminEntity to it, the pkiAdminEntity is going to inherit the polices of the group.
echo "Creating pkiadmins group"
vault write identity/group name=pkiadmins policies=pkiadminpolicy member_entity_ids=`cat _vaultSetup/pkiAdminEntityID.txt`  > /dev/null 2>&1