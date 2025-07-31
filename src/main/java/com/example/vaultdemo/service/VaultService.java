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

//    public VaultResponse getVaultHealth() {
//        return vaultTemplate.opsForSys().health();
//    }
}