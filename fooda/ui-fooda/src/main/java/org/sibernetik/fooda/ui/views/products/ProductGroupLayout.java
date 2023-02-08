package org.sibernetik.fooda.ui.views.products;

import com.vaadin.flow.component.Tag;
import com.vaadin.flow.component.UI;
import com.vaadin.flow.component.notification.Notification;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;

import java.util.List;
import java.util.Map;

@Tag("fooda-product-group-layout")
public class ProductGroupLayout extends VerticalLayout {
    
    public ProductGroupLayout(List<Map<String, Object>> products, Integer rowsCount, Integer columnsCount){

        initStyle();

        int productsCount = products.size();

        if(!products.isEmpty()){

            UI.getCurrent().getPage().retrieveExtendedClientDetails(receiver -> {
                int screenWidth = receiver.getScreenWidth();


                if(screenWidth > 0 && screenWidth < 450){

                    for(int index = 0; index < productsCount; index++){
                        ProductLayout pl = new ProductLayout(products.get(index));
                        add(pl);
                    }

                    Notification.show("You are using a smartphone.");

                } else if (screenWidth > 450 && screenWidth < 650){
                    
                    for(int index = 0; index < productsCount / 2; index++){
                        ProductLayout pl = new ProductLayout(products.get(index));
                        add(pl);
                    }

                    Notification.show("You are using a tablet/phablet.");

                } else {
                    for(int index = 0; index < productsCount / 4; index++){
                        ProductLayout pl = new ProductLayout(products.get(index));
                        add(pl);
                    }

                    Notification.show("You are using a desktop/laptop.");
                }
            });

        }
    }

    public void initStyle(){
        setMargin(true);
        setPadding(true);
        setSpacing(false);

        getStyle()
                .set("display", "flex")
                .set("flex-wrap", "wrap")
                .set("justify-content","space-between");
    }

}
