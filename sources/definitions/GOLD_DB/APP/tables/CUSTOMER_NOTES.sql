-- Table GOLD_DB.APP.CUSTOMER_NOTES : user-entered data from the app.
-- Owned by DCM (not dbt): dbt rebuilds its tables and would wipe user data.
-- Written only through APP.SP_ADD_NOTE.

DEFINE TABLE {{ db('GOLD') }}.APP.CUSTOMER_NOTES (
  NOTE_ID      NUMBER DEFAULT {{ db('GOLD') }}.APP.NOTE_SEQ.NEXTVAL,
  CUSTOMER_ID  NUMBER,
  NOTE         VARCHAR,
  CREATED_AT   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
)
COMMENT = 'User-entered data from the app (not rebuilt by pipelines)';

GRANT SELECT ON TABLE {{ db('GOLD') }}.APP.CUSTOMER_NOTES TO DATABASE ROLE {{ db('GOLD') }}.READ;
GRANT INSERT, UPDATE, DELETE ON TABLE {{ db('GOLD') }}.APP.CUSTOMER_NOTES TO DATABASE ROLE {{ db('GOLD') }}.WRITE;
