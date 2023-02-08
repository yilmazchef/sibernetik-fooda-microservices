package org.sibernetik.fooda.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

import com.icoderman.woocommerce.*;

@RestController
@RequestMapping("")
public class WooCommerceController {

    @Autowired
    private WooCommerce wooCommerce;

    @PostMapping("/products/create")
    public Map<String, Object> createProduct(Map<String, Object> productInfo) {
        Map<String, Object> product = (Map<String, Object>) wooCommerce.create(EndpointBaseType.PRODUCTS.getValue(), productInfo);
        return product;
    }

    @GetMapping("/products")
    public List<Map<String, Object>> getAllProducts() {
        Map<String, String> params = new HashMap<>();
        params.put("per_page", "100");
        params.put("offset", "0");
        List<Map<String, Object>> products = (List<Map<String, Object>>) wooCommerce.getAll(EndpointBaseType.PRODUCTS.getValue(), params);
        return products;
    }


    @GetMapping("/products/{id}")
    public Map<String, Object> getProductById(@PathVariable("id") Integer id) {
        Map<String, Object> product = (Map<String, Object>) wooCommerce.get(EndpointBaseType.PRODUCTS.getValue(), id);
        return product;
    }


    @PutMapping("/products/{id}")
    public Map<String, Object> updateProduct(@PathVariable("id") Integer id, Map<String, Object> productInfo) {
        Map<String, Object> product = (Map<String, Object>) wooCommerce.update(EndpointBaseType.PRODUCTS.getValue(), 10, productInfo);
        return product;
    }

    @DeleteMapping("/products/{id}")
    public Map<String, Object> deleteProduct(@PathVariable("id") Integer id) {
        Map<String, Object> product = (Map<String, Object>) wooCommerce.delete(EndpointBaseType.PRODUCTS.getValue(), id);
        return product;
    }

    @PatchMapping("/products/{id}")
    public Map<String, Object> batchVariation(@PathVariable("id") Integer id, List<Map<String, Object>> variations) {
        Map<String, Object> reqOptions = new HashMap<>();
        reqOptions.put("update", variations);
        Map<String, Object> response = (Map<String, Object>) wooCommerce.batch(String.format("products/%d/variations", id), reqOptions);
        return response;
    }

    @PatchMapping("/products/{id}/batch")
    public Map<String, Object> batchProduct(@PathVariable("id") Integer id, @RequestParam("name") String name) {
        List<Map<String, Object>> products = new ArrayList<>();
        Map<String, Object> product = new HashMap<>();
        product.put("id", id);
        product.put("name", name);
        products.add(product);
        Map<String, Object> reqOptions = new HashMap<>();
        reqOptions.put("update", products);
        Map<String, Object> response = (Map<String, Object>) wooCommerce.batch(EndpointBaseType.PRODUCTS.getValue(), reqOptions);
        return response;
    }

}
