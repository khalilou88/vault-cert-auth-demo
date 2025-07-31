package com.example.vaultdemo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.vault.annotation.VaultPropertySource;

@Configuration
@VaultPropertySource("secret/vault-demo")
@VaultPropertySource("secret/vault-demo/dev")
public class VaultConfig {
    // Additional Vault configuration can be added here
}