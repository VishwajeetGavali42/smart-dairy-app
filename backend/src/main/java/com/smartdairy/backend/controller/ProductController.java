package com.smartdairy.backend.controller;

import com.smartdairy.backend.entity.Product;
import com.smartdairy.backend.repository.ProductRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    private final ProductRepository productRepository;

    public ProductController(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @GetMapping
    public List<Product> getAllProducts(@RequestParam(required = false) String category) {
        if (category != null && !category.isEmpty() && !"All".equalsIgnoreCase(category)) {
            return productRepository.findByCategory(category);
        }
        return productRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable String id) {
        return productRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Product createProduct(@RequestBody Product product) {
        if (product.getId() == null || product.getId().trim().isEmpty()) {
            product.setId("PROD_" + System.currentTimeMillis());
        }
        return productRepository.save(product);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Product> updateProduct(@PathVariable String id, @RequestBody Product updated) {
        return productRepository.findById(id).map(existing -> {
            if (updated.getName() != null) existing.setName(updated.getName());
            if (updated.getCategory() != null) existing.setCategory(updated.getCategory());
            if (updated.getPrice() != null) existing.setPrice(updated.getPrice());
            if (updated.getStock() != null) existing.setStock(updated.getStock());
            if (updated.getUnit() != null) existing.setUnit(updated.getUnit());
            if (updated.getDescription() != null) existing.setDescription(updated.getDescription());
            existing.setActive(updated.isActive());
            return ResponseEntity.ok(productRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/{id}/stock")
    public ResponseEntity<Product> adjustStock(@PathVariable String id, @RequestBody Map<String, Integer> payload) {
        return productRepository.findById(id).map(product -> {
            Integer delta = payload.getOrDefault("delta", 0);
            int newStock = (product.getStock() != null ? product.getStock() : 0) + delta;
            if (newStock < 0) {
                return ResponseEntity.badRequest().<Product>build();
            }
            product.setStock(newStock);
            return ResponseEntity.ok(productRepository.save(product));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable String id) {
        if (productRepository.existsById(id)) {
            productRepository.deleteById(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
