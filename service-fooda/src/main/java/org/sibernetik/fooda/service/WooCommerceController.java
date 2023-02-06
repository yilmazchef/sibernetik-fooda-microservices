package org.sibernetik.fooda.service;

import org.springframework.web.bind.annotation.*;

import java.util.*;

import com.icoderman.woocommerce.oauth.*;
import com.icoderman.woocommerce.*;

@RestController
public class WooCommerceController {

    private static final String CONSUMER_KEY = "ck_b969666524ce65b909b7cb9c3b3598f49a613ef8";
    private static final String CONSUMER_SECRET = "cs_bb15fb7a9b1a84d69c1ae864588985aa2df66f68";
    private static final String WC_URL = "http://localhost/index.php";

    private WooCommerce wooCommerce;

    public WooCommerceController(WooCommerce wooCommerce){
        wooCommerce = new WooCommerceAPI(new OAuthConfig(WC_URL, CONSUMER_KEY, CONSUMER_SECRET), ApiVersionType.V2);
    }

    @PostMapping("products/create")
    public Map createProduct(Map<String, Object> productInfo) {
        Map product = wooCommerce.create(EndpointBaseType.PRODUCTS.getValue(), productInfo);
        return product;
    }

    @GetMapping("products")
    public Object getAllProducts() {
        Map<String, String> params = new HashMap<>();
        params.put("per_page", "100");
        params.put("offset", "0");
        Object products = wooCommerce.getAll(EndpointBaseType.PRODUCTS.getValue(), params);
        return products;
    }


    @GetMapping("products/{id}")
    public Map getProductById(@PathVariable("id") Integer id) {
        Map product = wooCommerce.get(EndpointBaseType.PRODUCTS.getValue(), id);
        return product;
    }


    @PutMapping("products/{id}")
    public Map updateProduct(@PathVariable("id") Integer id, Map<String, Object> productInfo) {
        Map product = wooCommerce.update(EndpointBaseType.PRODUCTS.getValue(), 10, productInfo);
        return product;
    }

    @DeleteMapping("products/{id}")
    public Map deleteProduct(@PathVariable("id") Integer id) {
        Map product = wooCommerce.delete(EndpointBaseType.PRODUCTS.getValue(), id);
        return product;
    }

    @PatchMapping("products/{id}")
    public Map batchVariation(@PathVariable("id") Integer id, List<Map<String, Object>> variations) {
        Map<String, Object> reqOptions = new HashMap<>();
        reqOptions.put("update", variations);
        Map response = wooCommerce.batch(String.format("products/%d/variations", id), reqOptions);
        return response;
    }

    @PatchMapping("products/{id}/batch")
    public Map batchProduct(@PathVariable("id") Integer id, @RequestParam("name") String name) {
        List<Map<String, Object>> products = new ArrayList<>();
        Map<String, Object> product = new HashMap<>();
        product.put("id", id);
        product.put("name", name);
        products.add(product);
        Map<String, Object> reqOptions = new HashMap<>();
        reqOptions.put("update", products);
        Map response = wooCommerce.batch(EndpointBaseType.PRODUCTS.getValue(), reqOptions);
        return response;
    }

}
