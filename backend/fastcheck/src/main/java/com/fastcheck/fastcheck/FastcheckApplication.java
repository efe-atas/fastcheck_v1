package com.fastcheck.fastcheck;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class FastcheckApplication {

	public static void main(String[] args) {
		SpringApplication.run(FastcheckApplication.class, args);
	}

}
