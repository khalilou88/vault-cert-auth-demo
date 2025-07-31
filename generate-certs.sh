#!/bin/bash

echo "Creating JKS keystore directly with keytool..."

# Generate key pair directly in JKS format
keytool -genkeypair \
    -alias vault-demo \
    -keyalg RSA \
    -keysize 2048 \
    -validity 365 \
    -keystore keystore.jks \
    -storepass changeit \
    -keypass changeit \
    -dname "CN=vault-demo-client,O=VaultDemo,C=US" \
    -noprompt

# Export the certificate for Vault configuration
keytool -exportcert \
    -alias vault-demo \
    -keystore keystore.jks \
    -storepass changeit \
    -file client-cert.pem \
    -rfc

echo "Files created:"
ls -la keystore.jks client-cert.pem