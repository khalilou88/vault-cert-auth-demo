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




# Get the certificate with better error handling
echo | timeout 10 openssl s_client -connect localhost:8200 -servername localhost 2>/dev/null | \
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > vault-server-cert.pem

# Check if we got a certificate
if [ -s vault-server-cert.pem ]; then
    echo "✅ Certificate retrieved successfully"
    cat vault-server-cert.pem
else
    echo "❌ Failed to get certificate from Vault server"
    rm -f vault-server-cert.pem
fi


# Import into truststore
keytool -import -trustcacerts -alias vault-server \
    -file vault-server-cert.pem \
    -keystore truststore.jks \
    -storepass changeit \
    -noprompt


cp keystore.jks src/main/resources/

 # Copy to resources
 cp truststore.jks src/main/resources/