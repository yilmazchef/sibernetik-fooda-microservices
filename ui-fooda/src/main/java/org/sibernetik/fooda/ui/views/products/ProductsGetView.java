package org.sibernetik.fooda.ui.views.helloworld;

import com.google.common.util.concurrent.Service;
import com.vaadin.flow.component.Key;
import com.vaadin.flow.component.button.Button;
import com.vaadin.flow.component.notification.Notification;
import com.vaadin.flow.component.orderedlayout.HorizontalLayout;
import com.vaadin.flow.component.textfield.TextField;
import com.vaadin.flow.router.PageTitle;
import com.vaadin.flow.router.Route;
import com.vaadin.flow.router.RouteAlias;

import java.util.*;

import javax.annotation.security.PermitAll;

import org.sibernetik.fooda.ui.services.ServiceFooda;

import com.vaadin.flow.component.dependency.CssImport;
import com.vaadin.flow.component.html.Span;

@PageTitle("Woocommerce Products Page")
@Route(value = "products")
@PermitAll
public class ProductsGetView extends HorizontalLayout {

    private final ServiceFooda serviceFooda;

    public ProductsGetView(ServiceFooda serviceFooda) {

        this.serviceFooda = serviceFooda;
        initStyle();
        
        List<Map<String,Object>> products = (List<Map<String,Object>>) this.serviceFooda.getAllProducts();

        if(!products.isEmpty()){
            
            for (Map<String,Object> p : products){
                Span productInfo = new Span(p.get("name").toString());
                add(productInfo);
            }

        }

    }

    public void initStyle(){
        setMargin(true);
        setPadding(true);
    }

}
