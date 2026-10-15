-- Environment databases and schemas
-- SILVER: cleaned / conformed data (procs + dbt stg_/int_ models)
-- GOLD  : business-ready data (dbt dim_/fct_, views for BI and the app)

DEFINE DATABASE {{ db('SILVER') }}
  DATA_RETENTION_TIME_IN_DAYS = {{ retention_days }}
  COMMENT = '{{ project }} {{ env }} Silver layer (managed by DCM)';

DEFINE SCHEMA {{ db('SILVER') }}.CORE
  COMMENT = 'Conformed tables, procedures and functions';

DEFINE SCHEMA {{ db('SILVER') }}.STAGING
  COMMENT = 'dbt staging models (stg_). Tables/views inside are created by dbt, not DCM';

DEFINE DATABASE {{ db('GOLD') }}
  DATA_RETENTION_TIME_IN_DAYS = {{ retention_days }}
  COMMENT = '{{ project }} {{ env }} Gold layer (managed by DCM)';

DEFINE SCHEMA {{ db('GOLD') }}.MART
  COMMENT = 'Dimensions, facts (dbt dim_/fct_) and reporting views';

DEFINE SCHEMA {{ db('GOLD') }}.APP
  COMMENT = 'Application objects: app tables, app procedures, Streamlit';
