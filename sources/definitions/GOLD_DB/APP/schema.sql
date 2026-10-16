-- Schema GOLD_DB.APP : everything the Streamlit app uses.
--   DCM (this folder): app data tables, sequences, write procedures, the Streamlit object
--   dbt (dbt/models/GOLD_DB/APP/): read views for the app

DEFINE SCHEMA {{ db('GOLD') }}.APP
  COMMENT = 'Application objects: app tables, app procedures, Streamlit';

GRANT USAGE ON SCHEMA {{ db('GOLD') }}.APP TO DATABASE ROLE {{ db('GOLD') }}.READ;
GRANT USAGE ON SCHEMA {{ db('GOLD') }}.APP TO DATABASE ROLE {{ db('GOLD') }}.APP;
