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