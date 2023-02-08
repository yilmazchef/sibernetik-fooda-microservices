package org.sibernetik.fooda.ui.services;

import org.sibernetik.fooda.ui.data.dto.Greeting;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.*;


@Service
@FeignClient(name = "service-fooda", url = "http://localhost:8000")
public interface ServiceFooda {

    @GetMapping("products")
    public List getAllProducts();
    
}
