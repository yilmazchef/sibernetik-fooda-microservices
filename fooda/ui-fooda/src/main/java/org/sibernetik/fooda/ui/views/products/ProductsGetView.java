package org.sibernetik.fooda.ui.views.products;

import com.vaadin.flow.component.orderedlayout.VerticalLayout;
import com.vaadin.flow.router.PageTitle;
import com.vaadin.flow.router.Route;
import org.sibernetik.fooda.ui.services.ServiceFooda;
import org.sibernetik.fooda.ui.utils.SearchUtils;

import javax.annotation.security.PermitAll;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@PageTitle("Woocommerce Products Page")
@Route(value = "products")
@PermitAll
public class ProductsGetView extends VerticalLayout {

    private final ServiceFooda serviceFooda;

    public ProductsGetView(ServiceFooda serviceFooda) {

        this.serviceFooda = serviceFooda;
        initStyle();
        List<Map<String,Object>> products = (List<Map<String,Object>>) this.serviceFooda.getAllProducts();

        ProductSearchLayout searchLayout = new ProductSearchLayout();
        searchLayout.addSearchClickListener(
                onClick -> {
                    String nameExpected = searchLayout.getNameComp().getValue().toLowerCase();
                    Double minPriceExpected = searchLayout.getPriceMinComp().getValue();
                    Double maxPriceExpected = searchLayout.getPriceMaxComp().getValue();

                    List<Map<String, Object>> results = products
                            .stream()
                            .filter(p -> {
                                double priceActual = Double.parseDouble(p.get("price").toString());
                                String nameActual = p.get("name").toString().toLowerCase();
                                int nameDistance = SearchUtils.calculateDistance(nameExpected, nameActual);

                                return (priceActual > minPriceExpected && priceActual < maxPriceExpected) ||
                                        (nameActual.contains(nameExpected) || nameExpected.contains(nameActual));
                            })
                            .collect(Collectors.toList());

                    ProductGroupLayout productGroup = new ProductGroupLayout(results, (results.size() / 4), 3);

                    add(
                            productGroup
                    );
                }
        );

        add(
            searchLayout
        );

    }

    public void initStyle(){
        setMargin(true);
        setPadding(true);
        setSpacing(false);
    }

}
