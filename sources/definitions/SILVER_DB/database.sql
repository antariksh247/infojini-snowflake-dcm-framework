-- Database INFOJINI_<ENV>_SILVER_DB : cleaned / conformed data.
-- Tables and views in this database are built by dbt (dbt/models/SILVER_DB/).
-- Access roles (database roles): READ, WRITE (WRITE includes READ).

DEFINE DATABASE {{ db('SILVER') }}
  DATA_RETENTION_TIME_IN_DAYS = {{ retention_days }}
  COMMENT = '{{ project }} {{ env }} Silver layer (managed by DCM)';

DEFINE DATABASE ROLE {{ db('SILVER') }}.READ  COMMENT = 'Read all data in {{ db('SILVER') }}';
DEFINE DATABASE ROLE {{ db('SILVER') }}.WRITE COMMENT = 'Read + DML on all tables in {{ db('SILVER') }}';

GRANT DATABASE ROLE {{ db('SILVER') }}.READ TO DATABASE ROLE {{ db('SILVER') }}.WRITE;
GRANT USAGE ON DATABASE {{ db('SILVER') }} TO DATABASE ROLE {{ db('SILVER') }}.READ;
