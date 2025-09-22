const createTable = """
CREATE TABLE IF NOT EXISTS {{ table_name }} (
  id SERIAL PRIMARY KEY,
  item VARCHAR(255) NOT NULL,
  event_start TIMESTAMP NOT NULL,
  event_end TIMESTAMP,
  event_action SMALLINT NOT NULL DEFAULT 0,
  CONSTRAINT chk_event_dates CHECK (event_end IS NULL OR event_end >= event_start),
  CONSTRAINT unique_item_event_start UNIQUE (item, event_start)
);
""";

const startEvent = """
  INSERT INTO {{ table_name }} (item, event_start)
  VALUES ({{ item }}, {{ event_start }})
  ON CONFLICT (item, event_start) DO NOTHING
  RETURNING id;
""";

const unfinishedEvent = """
  UPDATE {{ table_name }}
  SET event_action = {{ value }}
  WHERE id IN (
    SELECT id FROM {{ table_name }}
    WHERE event_end is NULL
      AND item = {{ item }}
      AND event_start < {{ event_start }}
      AND event_action != {{ value }}
  );
""";

const unfinishedEventForActive = """
UPDATE {{ table_name }}
SET event_action = {{ value }}
WHERE item = {{ item }}
  AND event_end IS NULL
  AND event_start < (
      SELECT MAX(event_start)
      FROM {{ table_name }}
      WHERE item = {{ item }}
        AND event_end IS NULL
  );
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
  RETURNING id;
""";

const getEvents = """
SELECT * FROM {{ table_name }} {{ WHERE }}
ORDER BY event_start DESC, id DESC
LIMIT {{ limit }}
OFFSET {{ offset }};
""";

const acknowledge = """
UPDATE {{ table_name }}
SET event_action = 1
WHERE id = ANY({{ ids }}) and event_action = 0
""";

const selectById = """
SELECT * FROM {{ table_name }} WHERE id = ANY({{ id }})
""";

const remove = """
SELECT * FROM {{ table_name }}
WHERE event_start < {{ event_start }};
""";

String addTableNameToSql(String sql, String tableName) {
  return sql.replaceAll('{{ table_name }}', tableName);
}
