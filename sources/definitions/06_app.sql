-- App layer (DCM part): stateful app data + the write API.
--   CUSTOMER_NOTES holds user-entered data -> DCM (dbt would rebuild / wipe it).
--   SP_ADD_NOTE is the app's write API     -> DCM.
-- Read views for the app (V_CUSTOMER_NOTES, V_CUSTOMER_ORDERS) are dbt models;
-- dbt grants SELECT on them to the APP database role (macros/grant_app.sql).

DEFINE SEQUENCE {{ db('GOLD') }}.APP.NOTE_SEQ START = 1 INCREMENT = 1;

DEFINE TABLE {{ db('GOLD') }}.APP.CUSTOMER_NOTES (
  NOTE_ID      NUMBER DEFAULT {{ db('GOLD') }}.APP.NOTE_SEQ.NEXTVAL,
  CUSTOMER_ID  NUMBER,
  NOTE         VARCHAR,
  CREATED_AT   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
)
COMMENT = 'User-entered data from the app (not rebuilt by pipelines)';

DEFINE PROCEDURE {{ db('GOLD') }}.APP.SP_ADD_NOTE(P_CUSTOMER_ID NUMBER, P_NOTE VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (P_NOTE IS NULL OR TRIM(P_NOTE) = '') THEN
    RETURN 'ERROR: note is empty';
  END IF;
  INSERT INTO {{ db('GOLD') }}.APP.CUSTOMER_NOTES (CUSTOMER_ID, NOTE) VALUES (:P_CUSTOMER_ID, :P_NOTE);
  RETURN 'OK';
END;
$$;

-- Analysts / engineers (READ / WRITE)
GRANT SELECT ON TABLE {{ db('GOLD') }}.APP.CUSTOMER_NOTES TO DATABASE ROLE {{ db('GOLD') }}.READ;
GRANT INSERT, UPDATE, DELETE ON TABLE {{ db('GOLD') }}.APP.CUSTOMER_NOTES TO DATABASE ROLE {{ db('GOLD') }}.WRITE;
GRANT USAGE ON PROCEDURE {{ db('GOLD') }}.APP.SP_ADD_NOTE(NUMBER, VARCHAR) TO DATABASE ROLE {{ db('GOLD') }}.WRITE;

-- App role: read views (granted by dbt) + write proc only, no direct table access
DEFINE DATABASE ROLE {{ db('GOLD') }}.APP COMMENT = 'App access: read views, write via procedures';
GRANT USAGE ON DATABASE {{ db('GOLD') }}        TO DATABASE ROLE {{ db('GOLD') }}.APP;
GRANT USAGE ON SCHEMA {{ db('GOLD') }}.APP      TO DATABASE ROLE {{ db('GOLD') }}.APP;
GRANT USAGE ON SCHEMA {{ db('GOLD') }}.MART     TO DATABASE ROLE {{ db('GOLD') }}.APP;
GRANT USAGE ON PROCEDURE {{ db('GOLD') }}.APP.SP_ADD_NOTE(NUMBER, VARCHAR) TO DATABASE ROLE {{ db('GOLD') }}.APP;

{% for r in app_users %}GRANT DATABASE ROLE {{ db('GOLD') }}.APP TO ROLE {{ r }};
{% endfor %}
