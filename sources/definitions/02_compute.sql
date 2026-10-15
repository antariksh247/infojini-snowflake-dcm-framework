-- One transform warehouse per environment (procs, tasks, dbt)
DEFINE WAREHOUSE {{ wh('TRANSFORM') }}
  WAREHOUSE_SIZE = '{{ wh_size }}'
  AUTO_SUSPEND = {{ auto_suspend }}
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = '{{ project }} {{ env }} transform warehouse (managed by DCM)';
