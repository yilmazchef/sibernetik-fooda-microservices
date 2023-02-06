package org.sibernetik.fooda.service;



@Configuration
public class WooConfig {
    

    @Bean
    public WooCommerce authenticateWoocommerce(){
        return new WooCommerceAPI(new OAuthConfig(WC_URL, CONSUMER_KEY, CONSUMER_SECRET), ApiVersionType.V2);
    }

}
