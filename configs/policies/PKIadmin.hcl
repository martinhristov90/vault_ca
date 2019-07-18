# Enable secrets engine
path "sys/mounts/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# List enabled secrets engine
path "sys/mounts" {
  capabilities = [ "read", "list" ]
}

# Work with pki secrets engine
path "vault-ca-root*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "vault-ca-intermediate*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}