-- Streamlit GOLD_DB.APP.STR_CUSTOMER_APP
-- Code: apps/STR_CUSTOMER_APP/ (asset "str_customer_app" in manifest.yml).
-- Reads Gold views, writes only via APP.SP_ADD_NOTE. Warehouse runtime (no compute pool).

DEFINE STREAMLIT {{ db('GOLD') }}.APP.STR_CUSTOMER_APP
  FROM 'asset://str_customer_app/'
  MAIN_FILE = 'streamlit_app.py'
  RUNTIME_NAME = 'SYSTEM$WAREHOUSE_RUNTIME'
  QUERY_WAREHOUSE = {{ wh('TRANSFORM') }}
  TITLE = '{{ project }} customer app ({{ env }})';

GRANT USAGE ON STREAMLIT {{ db('GOLD') }}.APP.STR_CUSTOMER_APP TO DATABASE ROLE {{ db('GOLD') }}.APP;
