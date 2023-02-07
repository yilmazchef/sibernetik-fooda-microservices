package org.sibernetik.fooda.ui.views.products;

import com.vaadin.flow.component.Key;
import com.vaadin.flow.component.Unit;
import com.vaadin.flow.component.button.Button;
import com.vaadin.flow.component.notification.Notification;
import com.vaadin.flow.component.orderedlayout.HorizontalLayout;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;
import com.vaadin.flow.router.PageTitle;
import com.vaadin.flow.router.Route;

import java.util.*;

import javax.annotation.security.PermitAll;

import org.sibernetik.fooda.ui.services.ServiceFooda;

import com.vaadin.flow.component.html.Image;
import com.vaadin.flow.component.html.Span;

@PageTitle("Woocommerce Products Page")
@Route(value = "products")
@PermitAll
public class ProductsGetView extends VerticalLayout {

    private final ServiceFooda serviceFooda;

    public ProductsGetView(ServiceFooda serviceFooda) {

        this.serviceFooda = serviceFooda;
        initStyle();
        
        List<Map<String,Object>> products = (List<Map<String,Object>>) this.serviceFooda.getAllProducts();

        if(!products.isEmpty()){
            
            for (Map<String,Object> p : products){

                HorizontalLayout productLayout = new HorizontalLayout();
                productLayout.setMargin(false);
                productLayout.setPadding(false);
                productLayout.setSpacing(false);
                productLayout.setWidthFull();
                productLayout.setMaxHeight(400, Unit.PIXELS);
    
                VerticalLayout leftLayout = new VerticalLayout();
                leftLayout.setMargin(false);
                leftLayout.setPadding(false);
                leftLayout.setSpacing(false);
                leftLayout.setSizeFull();
    
                VerticalLayout rightLayout = new VerticalLayout();
                rightLayout.setMargin(false);
                rightLayout.setPadding(false);
                rightLayout.setSpacing(false);
                rightLayout.setSizeFull();
               

                String productName = p.get("name").toString();
                List<Map<String,Object>> imageList = (List<Map<String,Object>>)p.get("images");
                String imageUrl = imageList.get(0).get("src").toString();

                Image imgComp = new Image(imageUrl, productName);
                Span nameComp = new Span(productName);
                
                leftLayout.add(imgComp);
                rightLayout.add(nameComp);

                productLayout.setFlexGrow(0.5, leftLayout);
                productLayout.setFlexGrow(1, rightLayout);
    
                productLayout.add(
                    leftLayout, rightLayout
                );
    
                add(productLayout);

            }
        }
    }

    public void initStyle(){
        setMargin(true);
        setPadding(true);
    }

}
