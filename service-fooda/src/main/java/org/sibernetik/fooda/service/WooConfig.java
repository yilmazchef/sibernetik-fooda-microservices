package org.sibernetik.fooda.service;

import com.icoderman.woocommerce.oauth.*;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.icoderman.woocommerce.*;

@Configuration
public class WooConfig {
    
    private final String CONSUMER_KEY = "ck_b969666524ce65b909b7cb9c3b3598f49a613ef8";
    private final String CONSUMER_SECRET = "cs_bb15fb7a9b1a84d69c1ae864588985aa2df66f68";
    private final String WC_URL = "http://localhost:8888/index.php";

    @Bean
    public WooCommerce authenticateWoocommerce(){
        return new WooCommerceAPI(new OAuthConfig(WC_URL, CONSUMER_KEY, CONSUMER_SECRET), ApiVersionType.V2);
    }

}
