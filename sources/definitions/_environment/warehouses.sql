-- Warehouses of the environment.  Name: INFOJINI_<ENV>_<PURPOSE>_WH
-- Used by: dbt (profiles.yml), tasks, Streamlit, procedures.

DEFINE WAREHOUSE {{ wh('TRANSFORM') }}
  WAREHOUSE_SIZE = '{{ wh_size }}'
  AUTO_SUSPEND = {{ auto_suspend }}
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = '{{ project }} {{ env }} transform warehouse (managed by DCM)';
