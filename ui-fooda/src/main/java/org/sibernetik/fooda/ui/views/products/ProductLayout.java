package org.sibernetik.fooda.ui.views.products;

import java.util.List;
import java.util.Map;

import com.vaadin.flow.component.Tag;
import com.vaadin.flow.component.Unit;
import com.vaadin.flow.component.html.Image;
import com.vaadin.flow.component.html.Span;
import com.vaadin.flow.component.orderedlayout.HorizontalLayout;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;

@Tag("fooda-product-layout")
public class ProductLayout extends VerticalLayout{
    
    public ProductLayout(Map<String, Object> p){

        HorizontalLayout productLayout = new HorizontalLayout();
        productLayout.setMargin(false);
        productLayout.setPadding(false);
        productLayout.setSpacing(false);
        productLayout.setWidthFull();
        productLayout.setMaxHeight(200, Unit.PIXELS);
        productLayout.setMaxWidth(250, Unit.PIXELS);

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
        imgComp.setMaxHeight(200, Unit.PIXELS);
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
