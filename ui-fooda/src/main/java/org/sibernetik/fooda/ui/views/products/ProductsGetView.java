package org.sibernetik.fooda.ui.views.products;

import java.util.List;
import java.util.Map;

import javax.annotation.security.PermitAll;

import org.sibernetik.fooda.ui.services.ServiceFooda;

import com.vaadin.flow.component.Unit;
import com.vaadin.flow.component.html.Image;
import com.vaadin.flow.component.html.Span;
import com.vaadin.flow.component.orderedlayout.HorizontalLayout;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;
import com.vaadin.flow.router.PageTitle;
import com.vaadin.flow.router.Route;

@PageTitle("Woocommerce Products Page")
@Route(value = "products")
@PermitAll
public class ProductsGetView extends VerticalLayout {

    private final ServiceFooda serviceFooda;

    public ProductsGetView(ServiceFooda serviceFooda) {

        this.serviceFooda = serviceFooda;
        initStyle();
        
        List<Map<String,Object>> products = (List<Map<String,Object>>) this.serviceFooda.getAllProducts();

        Integer productsCount = products.size();
        Integer noOfRows = ( productsCount / 4) + ( productsCount % 4 == 0 ? 0 : 1);  

        if(!products.isEmpty()){
            
            for (Map<String,Object> p : products){
                ProductLayout pl = new ProductLayout(p);
                add(pl);
            }
        }
    }

    public void initStyle(){
        setMargin(true);
        setPadding(true);
    }

}
