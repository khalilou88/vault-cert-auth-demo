#!/bin/bash

# Generate private key for client certificate
openssl genrsa -out client-key.pem 2048

# Generate certificate signing request
openssl req -new -key client-key.pem -out client-csr.pem -subj "/CN=vault-demo-client"

# Generate self-signed client certificate
openssl x509 -req -in client-csr.pem -signkey client-key.pem -out client-cert.pem -days 365

# Create PKCS12 keystore
openssl pkcs12 -export -in client-cert.pem -inkey client-key.pem -out keystore.p12 -name vault-demo -password pass:changeit

# Convert PKCS12 to JKS format
keytool -importkeystore -srckeystore keystore.p12 -srcstoretype PKCS12 -srcstorepass changeit -destkeystore keystore.jks -deststoretype JKS -deststorepass changeit

echo "Certificates generated:"
echo "- client-cert.pem (for Vault configuration)"
echo "- keystore.jks (for Spring Boot application)"