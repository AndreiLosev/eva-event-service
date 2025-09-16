const createTable = """
CREATE TABLE IF NOT EXISTS {{ table_name }} (
  id SERIAL PRIMARY KEY,
  item VARCHAR(255) NOT NULL,
  event_start TIMESTAMP NOT NULL,
  event_end TIMESTAMP,
  event_action SMALLINT NOT NULL DEFAULT 0,
  CONSTRAINT chk_event_dates CHECK (event_end >= event_start)
);

CREATE INDEX IF NOT EXISTS idx_events_event_start ON events(event_start);
CREATE INDEX IF NOT EXISTS idx_events_item ON events(item);
""";

const startEvent = """
  INSERT INTO {{ table_name }} (item, event_start)
  VALUES ({{ item }}, {{ event_start }});
""";

const endEvent = """
  UPDATE {{ table_name }}
  SET event_end = {{ event_end }}
  WHERE id IN (
      SELECT id
      FROM {{ table_name }}
      WHERE item = {{ item }}
        AND event_end IS NULL
      ORDER BY event_start DESC
      LIMIT 1
  )
""";

const getEvents = """
SELECT * FROM {{ table_name }}
ORDER BY event_start DESC, id DESC
LIMIT {{ limit }}
OFFSET {{ offset }};
""";

const acknowledge = """
UPDATE {{ table_name }}
SET event_action = 1
WHERE id = ANY({{ ids }})
""";

String addTableNameToSql(String sql, String tableName) {
  return sql.replaceAll('{{ table_name }}', tableName);
}
