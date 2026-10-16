-- Schema SILVER_DB.STAGING : dbt staging models (stg_*), one per Bronze table.
-- Objects inside: dbt/models/SILVER_DB/STAGING/

DEFINE SCHEMA {{ db('SILVER') }}.STAGING
  COMMENT = 'dbt staging models (stg_). Tables/views inside are created by dbt, not DCM';

GRANT USAGE ON SCHEMA {{ db('SILVER') }}.STAGING TO DATABASE ROLE {{ db('SILVER') }}.READ;
