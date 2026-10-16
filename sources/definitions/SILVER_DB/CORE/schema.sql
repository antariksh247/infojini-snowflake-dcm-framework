-- Schema SILVER_DB.CORE : procedures, functions and tasks (non-dbt logic).
-- Objects inside: tasks/, procedures/, functions/ (create the folder when needed)

DEFINE SCHEMA {{ db('SILVER') }}.CORE
  COMMENT = 'Conformed tables, procedures and functions';

GRANT USAGE ON SCHEMA {{ db('SILVER') }}.CORE TO DATABASE ROLE {{ db('SILVER') }}.READ;
