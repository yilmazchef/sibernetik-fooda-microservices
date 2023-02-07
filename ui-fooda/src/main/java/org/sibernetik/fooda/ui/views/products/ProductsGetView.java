package org.sibernetik.fooda.ui.views.products;

import java.util.List;
import java.util.Map;

import javax.annotation.security.PermitAll;

import org.sibernetik.fooda.ui.services.ServiceFooda;

import com.vaadin.flow.component.UI;
import com.vaadin.flow.component.Unit;
import com.vaadin.flow.component.html.Image;
import com.vaadin.flow.component.html.Span;
import com.vaadin.flow.component.notification.Notification;
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

        ProductGroupLayout productGroup = new ProductGroupLayout(products, (products.size() / 4), 3);

        add(
            productGroup
        );

    }

    public void initStyle(){
        setMargin(true);
        setPadding(true);
        setSpacing(false);
    }

}
