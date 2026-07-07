package com.kbeauty.myapp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GreenController {

    @GetMapping(value = {"/green", "/api/green"}, produces = "text/plain;charset=UTF-8")
    public String green() {
        return "cicd 완료";
        
    }
}
