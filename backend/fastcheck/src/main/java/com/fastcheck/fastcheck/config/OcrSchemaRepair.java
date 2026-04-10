package com.fastcheck.fastcheck.config;

import java.sql.Connection;
import java.util.Locale;
import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class OcrSchemaRepair implements CommandLineRunner {
    private static final Logger log = LoggerFactory.getLogger(OcrSchemaRepair.class);

    private final DataSource dataSource;
    private final JdbcTemplate jdbcTemplate;

    public OcrSchemaRepair(DataSource dataSource, JdbcTemplate jdbcTemplate) {
        this.dataSource = dataSource;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        String database = detectDatabaseProductName();
        if (database == null) {
            return;
        }

        if (database.contains("postgresql")) {
            executeRepair("ALTER TABLE ocr_jobs ALTER COLUMN ocr_result_json TYPE TEXT");
            return;
        }

        if (database.contains("h2")) {
            executeRepair("ALTER TABLE ocr_jobs ALTER COLUMN ocr_result_json CLOB");
            return;
        }

        log.info("Skipping OCR schema repair for unsupported database: {}", database);
    }

    private String detectDatabaseProductName() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.getMetaData().getDatabaseProductName().toLowerCase(Locale.ROOT);
        } catch (Exception exc) {
            log.warn("Could not detect database product for OCR schema repair", exc);
            return null;
        }
    }

    private void executeRepair(String sql) {
        try {
            jdbcTemplate.execute(sql);
        } catch (Exception exc) {
            log.warn("OCR schema repair could not ensure ocr_result_json large-text storage", exc);
        }
    }
}
