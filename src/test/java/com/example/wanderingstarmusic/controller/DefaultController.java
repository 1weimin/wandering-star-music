package com.example.wanderingstarmusic.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequestMapping("/hello")
@RestController
public class DefaultController {

    @GetMapping
    public String sayHello() {
        try {
            return "哈喽，这是一个音乐网站！";
        } catch (Exception e) {
            return "出现异常，请稍后再试！";
        }
    }
}