package org.sibernetik.fooda.service;

import com.icoderman.woocommerce.oauth.*;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.icoderman.woocommerce.*;

@Configuration
public class WooConfig {
    
    private final String CONSUMER_KEY = "ck_c265593a771c48e0efc26803b3ce33ee87185cb6";
    private final String CONSUMER_SECRET = "cs_120d54a1f2b765d5a3072872347de07726ec516f";
    private final String WC_URL = "http://localhost";

    @Bean
    public WooCommerce authenticateWoocommerce(){
        return new WooCommerceAPI(new OAuthConfig(WC_URL, CONSUMER_KEY, CONSUMER_SECRET), ApiVersionType.V2);
    }

}
