# Spring Boot Vault Certificate Authentication Demo

## Project Structure
```
vault-cert-auth-demo/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           └── vaultdemo/
│   │   │               ├── VaultDemoApplication.java
│   │   │               ├── config/
│   │   │               │   └── VaultConfig.java
│   │   │               ├── controller/
│   │   │               │   └── SecretController.java
│   │   │               └── service/
│   │   │                   └── VaultService.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── keystore.jks
│   │       └── vault-setup.sh
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── vaultdemo/
│                       └── VaultDemoApplicationTests.java
├── pom.xml
├── README.md
└── docker-compose.yml
```

## 1. Maven Dependencies (pom.xml)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>vault-cert-auth-demo</artifactId>
    <version>1.0.0</version>
    <name>vault-cert-auth-demo</name>
    <description>Demo project for Spring Cloud Vault Certificate Authentication</description>
    
    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2023.0.0</spring-cloud.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-vault-config</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

## 2. Application Configuration (application.yml)
```yaml
spring:
  application:
    name: vault-cert-auth-demo
  cloud:
    vault:
      # Vault server configuration
      uri: https://localhost:8200
      connection-timeout: 5000
      read-timeout: 15000
      
      # Certificate authentication configuration
      authentication: CERT
      ssl:
        key-store: classpath:keystore.jks
        key-store-password: changeit
        key-store-type: JKS
        cert-auth-path: cert
        # Optional: trust store configuration
        trust-store: classpath:truststore.jks
        trust-store-password: changeit
        trust-store-type: JKS
      
      # KV configuration
      kv:
        enabled: true
        backend: secret
        profile-separator: '/'
        default-context: application
        application-name: vault-demo
      
      # Generic secret backend configuration
      generic:
        enabled: true
        backend: secret
        profile-separator: '/'
        default-context: application
        application-name: vault-demo

server:
  port: 8080

# Logging configuration
logging:
  level:
    org.springframework.cloud.vault: DEBUG
    org.springframework.vault: DEBUG
    root: INFO

# Management endpoints
management:
  endpoints:
    web:
      exposure:
        include: health,info,vault
  endpoint:
    health:
      show-details: always
```

## 3. Main Application Class
```java
package com.example.vaultdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class VaultDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(VaultDemoApplication.class, args);
    }
}
```

## 4. Vault Configuration Class
```java
package com.example.vaultdemo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.vault.annotation.VaultPropertySource;

@Configuration
@VaultPropertySource("secret/vault-demo")
@VaultPropertySource("secret/vault-demo/dev")
public class VaultConfig {
    // Additional Vault configuration can be added here
}
```

## 5. Secret Controller
```java
package com.example.vaultdemo.controller;

import com.example.vaultdemo.service.VaultService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/secrets")
public class SecretController {

    @Autowired
    private VaultService vaultService;

    @Value("${database.password:not-found}")
    private String databasePassword;

    @Value("${api.key:not-found}")
    private String apiKey;

    @GetMapping("/properties")
    public Map<String, String> getProperties() {
        return Map.of(
            "database.password", databasePassword,
            "api.key", apiKey
        );
    }

    @GetMapping("/{path}")
    public Map<String, Object> getSecret(@PathVariable String path) {
        return vaultService.readSecret(path);
    }

    @PostMapping("/{path}")
    public void writeSecret(@PathVariable String path, @RequestBody Map<String, Object> data) {
        vaultService.writeSecret(path, data);
    }

    @DeleteMapping("/{path}")
    public void deleteSecret(@PathVariable String path) {
        vaultService.deleteSecret(path);
    }
}
```

## 6. Vault Service
```java
package com.example.vaultdemo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.vault.core.VaultTemplate;
import org.springframework.vault.support.VaultResponse;

import java.util.Map;

@Service
public class VaultService {

    @Autowired
    private VaultTemplate vaultTemplate;

    public Map<String, Object> readSecret(String path) {
        VaultResponse response = vaultTemplate.read("secret/data/" + path);
        return response != null ? (Map<String, Object>) response.getData().get("data") : null;
    }

    public void writeSecret(String path, Map<String, Object> data) {
        vaultTemplate.write("secret/data/" + path, Map.of("data", data));
    }

    public void deleteSecret(String path) {
        vaultTemplate.delete("secret/data/" + path);
    }

    public VaultResponse getVaultHealth() {
        return vaultTemplate.opsForSys().health();
    }
}
```

## 7. Test Class
```java
package com.example.vaultdemo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "spring.cloud.vault.enabled=false"
})
class VaultDemoApplicationTests {

    @Test
    void contextLoads() {
        // Test that application context loads successfully
    }
}
```

## 8. Docker Compose for Vault Setup
```yaml
version: '3.8'

services:
  vault:
    image: hashicorp/vault:1.15
    container_name: vault-server
    ports:
      - "8200:8200"
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: myroot
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
      VAULT_ADDR: http://0.0.0.0:8200
    cap_add:
      - IPC_LOCK
    volumes:
      - ./vault-data:/vault/data
      - ./vault-config:/vault/config
      - ./certs:/vault/certs
    command: >
      sh -c "
      vault server -dev -dev-root-token-id=myroot -dev-listen-address=0.0.0.0:8200
      "
```

## 9. Vault Setup Script (vault-setup.sh)
```bash
#!/bin/bash

# Set Vault address and token
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='myroot'

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
```

## 10. Certificate Generation Script
```bash
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
```

## 11. README.md
```markdown
# Spring Boot Vault Certificate Authentication Demo

This project demonstrates how to configure Spring Boot with HashiCorp Vault using certificate authentication.

## Prerequisites

- Java 17+
- Maven 3.6+
- Docker and Docker Compose
- OpenSSL
- HashiCorp Vault CLI

## Setup Instructions

1. **Generate Certificates**
   ```bash
   chmod +x generate-certs.sh
   ./generate-certs.sh
   ```

2. **Start Vault Server**
   ```bash
   docker-compose up -d vault
   ```

3. **Configure Vault**
   ```bash
   chmod +x vault-setup.sh
   ./vault-setup.sh
   ```

4. **Copy Keystore**
   ```bash
   cp keystore.jks src/main/resources/
   ```

5. **Run Application**
   ```bash
   mvn spring-boot:run
   ```

## Testing the Application

1. **Check Properties from Vault**
   ```bash
   curl http://localhost:8080/api/secrets/properties
   ```

2. **Read a Secret**
   ```bash
   curl http://localhost:8080/api/secrets/vault-demo
   ```

3. **Write a Secret**
   ```bash
   curl -X POST http://localhost:8080/api/secrets/vault-demo/test \
        -H "Content-Type: application/json" \
        -d '{"username": "testuser", "password": "testpass"}'
   ```

## Configuration Explanation

The key configuration for certificate authentication:

```yaml
spring:
  cloud:
    vault:
      authentication: CERT
      ssl:
        key-store: classpath:keystore.jks
        key-store-password: changeit
        key-store-type: JKS
        cert-auth-path: cert
```

- `authentication: CERT` - Enables certificate-based authentication
- `key-store` - Path to the JKS keystore containing the client certificate
- `key-store-password` - Password for the keystore
- `cert-auth-path` - Vault path for certificate authentication (default: "cert")

## Troubleshooting

1. **Certificate Issues**: Ensure the client certificate is properly configured in Vault
2. **SSL Issues**: Check trust store configuration if using custom CA
3. **Connection Issues**: Verify Vault server is running and accessible

## Security Notes

- In production, use proper certificate management
- Store keystore passwords securely (not in plain text)
- Use appropriate Vault policies with minimal required permissions
- Enable audit logging in Vault
```

## How to Use This Demo

1. **Clone and Setup**: Copy the files to your project directory
2. **Generate Certificates**: Run the certificate generation script
3. **Start Vault**: Use Docker Compose to start a Vault server
4. **Configure Vault**: Run the setup script to enable cert auth and create policies
5. **Run Application**: Start the Spring Boot application
6. **Test**: Use the provided endpoints to verify Vault integration

This demo shows a complete working example of Spring Cloud Vault with certificate authentication, including proper SSL configuration, secret management, and REST endpoints for testing.