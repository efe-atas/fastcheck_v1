package com.fastcheck.fastcheck.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI fastcheckOpenApi(@Value("${server.port:8080}") int serverPort) {
        String localServer = "http://127.0.0.1:" + serverPort;
        Info info = new Info()
                .title("FastCheck API")
                .description("""
                        FastCheck education module API. The contract mirrors the mobile client's \
                        `ApiConstants` constants and is versioned alongside the backend.
                        """)
                .version("v1")
                .contact(new Contact().name("FastCheck Developers"))
                .license(new License().name("Proprietary"));
        return new OpenAPI()
                .info(info)
                .components(new Components())
                .servers(List.of(new Server().url(localServer).description("Local Dev")));
    }
}
