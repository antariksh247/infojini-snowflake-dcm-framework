-- Database INFOJINI_<ENV>_GOLD_DB : business-ready data for BI, ML and apps.
-- Tables and views are built by dbt (dbt/models/GOLD_DB/), except app data (APP schema).
-- Access roles (database roles):
--   READ  : read everything            (analysts, BI, scientists)
--   WRITE : READ + DML                 (engineers, where allowed)
--   APP   : app views + app procedures only, no direct table access (Streamlit users)

DEFINE DATABASE {{ db('GOLD') }}
  DATA_RETENTION_TIME_IN_DAYS = {{ retention_days }}
  COMMENT = '{{ project }} {{ env }} Gold layer (managed by DCM)';

DEFINE DATABASE ROLE {{ db('GOLD') }}.READ  COMMENT = 'Read all data in {{ db('GOLD') }}';
DEFINE DATABASE ROLE {{ db('GOLD') }}.WRITE COMMENT = 'Read + DML on all tables in {{ db('GOLD') }}';
DEFINE DATABASE ROLE {{ db('GOLD') }}.APP   COMMENT = 'App access: read views, write via procedures';

GRANT DATABASE ROLE {{ db('GOLD') }}.READ TO DATABASE ROLE {{ db('GOLD') }}.WRITE;
GRANT USAGE ON DATABASE {{ db('GOLD') }} TO DATABASE ROLE {{ db('GOLD') }}.READ;
GRANT USAGE ON DATABASE {{ db('GOLD') }} TO DATABASE ROLE {{ db('GOLD') }}.APP;
