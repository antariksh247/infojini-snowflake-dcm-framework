-- Streamlit app (DCM asset). Code: assets/streamlit/ (see manifest.yml "assets").
-- Lives in GOLD_DB.APP, reads Gold views, writes only via APP.SP_ADD_NOTE.
-- Warehouse runtime set explicitly (no compute pool, packages from Snowflake Anaconda channel).
-- Container runtime would instead need RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11',
-- a pyproject.toml in the asset folder and access to a package repository.

DEFINE STREAMLIT {{ db('GOLD') }}.APP.STR_CUSTOMER_APP
  FROM 'asset://customer_app/'
  MAIN_FILE = 'streamlit_app.py'
  RUNTIME_NAME = 'SYSTEM$WAREHOUSE_RUNTIME'
  QUERY_WAREHOUSE = {{ wh('TRANSFORM') }}
  TITLE = '{{ project }} customer app ({{ env }})';

-- Who may open the app: the APP database role (-> INFOJINI_APP_USER in STAGE / PROD)
GRANT USAGE ON STREAMLIT {{ db('GOLD') }}.APP.STR_CUSTOMER_APP TO DATABASE ROLE {{ db('GOLD') }}.APP;
