-- Schema GOLD_DB.MART : dimensions, facts and reporting views (all dbt).
-- Objects inside: dbt/models/GOLD_DB/MART/

DEFINE SCHEMA {{ db('GOLD') }}.MART
  COMMENT = 'Dimensions, facts (dbt dim_/fct_) and reporting views';

GRANT USAGE ON SCHEMA {{ db('GOLD') }}.MART TO DATABASE ROLE {{ db('GOLD') }}.READ;
GRANT USAGE ON SCHEMA {{ db('GOLD') }}.MART TO DATABASE ROLE {{ db('GOLD') }}.APP;
