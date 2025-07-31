#!/bin/bash

# Set Vault address and token
export VAULT_ADDR='https://localhost:8200'
export VAULT_TOKEN='myroot'
export VAULT_SKIP_VERIFY=1  # Skip SSL verification for self-signed certs
export VAULT_SKIP_VERIFY=true

echo "Setting up Vault for certificate authentication..."

# Enable certificate authentication
vault auth enable cert

# Create a certificate role
vault write auth/cert/certs/vault-demo \
    display_name="Vault Demo Certificate" \
    policies="vault-demo-policy" \
    certificate=@client-cert.pem \
    ttl=3600

# Create a policy for the demo application
vault policy write vault-demo-policy - <<EOF
path "secret/data/vault-demo/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/vault-demo/*" {
  capabilities = ["list"]
}
EOF

# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Add some sample secrets
vault kv put secret/vault-demo database.password="super-secret-db-password"
vault kv put secret/vault-demo api.key="api-key-12345"
vault kv put secret/vault-demo/dev database.url="jdbc:postgresql://localhost:5432/devdb"

echo "Vault setup complete!"
echo "Secrets created:"
vault kv list secret/vault-demo