#!/usr/bin/env bash

mkdir -p /vaultCerts

mkdir -p /vaultCerts/rootCA

mkdir -p /vaultCerts/intermediateCA

mkdir -p /vaultCerts/certsUI

mkdir -p /etc/vault.d/certsUI

export VAULT_ADDR=http://127.0.0.1:8200

echo "Logging in as pkiadmin user..."
vault login -method=userpass username=pkiadmin password=${PKIpass} > /dev/null 2>&1

# Enables pki secret engine at path "vautl-ca-root".
echo "Enabling PKI secret engine at path vautl-ca-root..."
vault secrets enable -path vault-ca-root -max-lease-ttl=87600h pki > /dev/null 2>&1

# Setting up CRL and Issuing CA URLs for Root CA.
echo "Setting up CRL and Issuing CA URLs for Root CA..."
vault write vault-ca-root/config/urls issuing_certificates="http://127.0.0.1:8200/v1/vault-ca-root/ca" crl_distribution_points="http://127.0.0.1:8200/v1/vault-ca-root/crl" > /dev/null 2>&1

# Creates Root CA certificate, the private key is not shown, it is stored internally in Vault, the ca-key.pem file is going to be empty because of that.
echo "Generating Root CA..."
vault write -format=json vault-ca-root/root/generate/internal \
  common_name="vault-ca-root" ttl=87600h | tee \
  >(jq -r .data.certificate > /vaultCerts/rootCA/ca.pem) \
  >(jq -r .data.issuing_ca > /vaultCerts/rootCA/issuing_ca.pem) \
  >(jq -r .data.private_key > /vaultCerts/rootCA/ca-key.pem) > /dev/null 2>&1

# Enable pki secret engine at path "vault-ca-intermediate", going to be used for intermediate CA.
echo "Creating intermediate CA..."
vault secrets enable -path vault-ca-intermediate pki > /dev/null 2>&1
vault secrets tune -max-lease-ttl=87600h vault-ca-intermediate > /dev/null 2>&1

# Generating certificate signing request, to be signed by Root CA.
echo "Generating intermediate CSR..."
vault write -format=json vault-ca-intermediate/intermediate/generate/internal \
  common_name="vault-ca-intermediate" ttl=43800h | tee \
  >(jq -r .data.csr > /vaultCerts/intermediateCA/vault-ca-intermediate.csr) \
  >(jq -r .data.private_key > /vaultCerts/intermediateCA/vault-ca-intermediate.pem) > /dev/null 2>&1

# Signing the CSR with Root CA
echo "Signing intermediate CSR..."
vault write -format=json vault-ca-root/root/sign-intermediate \
  csr=@/vaultCerts/intermediateCA/vault-ca-intermediate.csr \
  common_name="vault-ca-intermediate" ttl=43800h | tee \
  >(jq -r .data.certificate > /vaultCerts/intermediateCA/vault-ca-intermediate.pem) \
  >(jq -r .data.issuing_ca > /vaultCerts/intermediateCA/vault-ca-intermediate_issuing_ca.pem) > /dev/null 2>&1

# Importing the already signed intermediate CA certificate.
vault write vault-ca-intermediate/intermediate/set-signed certificate=@/vaultCerts/intermediateCA/vault-ca-intermediate.pem > /dev/null 2>&1

# Setting up CRL and Issuing CA URLs for Intermediate CA.
echo "Setting up CRL and Issuing CA URLs for Intermediate CA..."
vault write vault-ca-intermediate/config/urls issuing_certificates="http://127.0.0.1:8200/v1/vault-ca-intermediate/ca" crl_distribution_points="http://127.0.0.1:8200/v1/vault-ca-intermediate/crl" > /dev/null 2>&1

# Create a role, to generate certificates with
echo "Creating \"localhost_role\"...  "
vault write vault-ca-intermediate/roles/localhost_role allow_any_name=true max_ttl="24h" > /dev/null 2>&1

# Issuing a certificte to be used by Vault UI.
echo "Issuing a x509 certificate... "
vault write -format=json vault-ca-intermediate/issue/localhost_role common_name=localhost ip_sans=127.0.0.1 format=pem ttl=60000| tee >(jq -r .data.certificate > /vaultCerts/certsUI/certificatePublic.pem)  >(jq -r .data.private_key > /vaultCerts/certsUI/certificatePrivate.pem) > /dev/null 2>&1
chmod 400 /vaultCerts/certsUI/certificatePrivate.pem

# Coping certificates chain and private key to be used for Vault UI. Root CA (third) -> Intermediate CA (second) -> Cert used by UI (first) (top to bottom)
cat /vaultCerts/certsUI/certificatePublic.pem /vaultCerts/intermediateCA/vault-ca-intermediate.pem /vaultCerts/rootCA/ca.pem > /etc/vault.d/certsUI/chainedCerts.pem
cp /vaultCerts/certsUI/certificatePrivate.pem /etc/vault.d/certsUI/

# Vault needs to own those files
chown -R vault:vault /etc/vault.d/certsUI/

# Copying the root CA to be imported in user's browser.
cp /vaultCerts/rootCA/ca.pem /vagrant/

echo "For more detailed information, look at the script \"vaultPKI.sh\"..."

