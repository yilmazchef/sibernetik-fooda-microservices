package org.sibernetik.fooda.ui.views.products;

import com.vaadin.flow.component.ClickEvent;
import com.vaadin.flow.component.ComponentEventListener;
import com.vaadin.flow.component.Tag;
import com.vaadin.flow.component.button.Button;
import com.vaadin.flow.component.icon.VaadinIcon;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;
import com.vaadin.flow.component.textfield.NumberField;
import com.vaadin.flow.component.textfield.TextField;
import lombok.Getter;

@Tag("fooda-product-layout")
public class ProductSearchLayout extends VerticalLayout{

    @Getter
    private final TextField nameComp;

    @Getter
    private final NumberField priceMinComp;

    @Getter
    private final NumberField priceMaxComp;

    @Getter
    private final Button searchComp;

    public ProductSearchLayout(){

        initStyle();

        nameComp = new TextField("Name");
        priceMaxComp = new NumberField("Price Min");
        priceMinComp = new NumberField("Price Max");

        searchComp = new Button("Search", VaadinIcon.SEARCH.create());

        add(
                nameComp,
                priceMinComp,
                priceMaxComp,
                searchComp
        );
    }

    public void addSearchClickListener(ComponentEventListener<ClickEvent<Button>> onClickEvent){
        searchComp.addClickListener(onClickEvent);
    }

    public void initStyle(){
        setMargin(false);
        setPadding(false);
        setSpacing(false);

        getStyle()
                .set("display", "flex")
                .set("flex-wrap", "wrap")
                .set("justify-content","space-between");
    }

}
