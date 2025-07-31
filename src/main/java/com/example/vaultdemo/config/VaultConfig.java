package com.example.vaultdemo.config;

import org.springframework.cloud.vault.config.SecretBackendConfigurer;
import org.springframework.cloud.vault.config.VaultConfigurer;
import org.springframework.context.annotation.Configuration;
import org.springframework.vault.annotation.VaultPropertySource;

//@Configuration
//@VaultPropertySource("secret/vault-demo")
//@VaultPropertySource("secret/vault-demo/dev")
//public class VaultConfig {
//    // Additional Vault configuration can be added here
//}


@Configuration
public class VaultConfig implements VaultConfigurer {

    @Override
    public void addSecretBackends(SecretBackendConfigurer configurer) {
        // Configure additional secret backends if needed
        configurer.add("secret/vault-demo");
        configurer.add("secret/vault-demo/dev");
    }
}