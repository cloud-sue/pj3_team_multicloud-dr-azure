package com.kbeauty.myapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// Spring Session Redis 활성화
import org.springframework.session.data.redis.config.annotation.web.http.EnableRedisHttpSession;

// Spring Session Redis 활성화
@EnableRedisHttpSession
@SpringBootApplication
public class KbeautyApplication {

	public static void main(String[] args) {
		SpringApplication.run(KbeautyApplication.class, args);
	}

}
