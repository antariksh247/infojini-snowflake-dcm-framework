{# Post-hook: SELECT on the model to the app database role <DB>.APP (created by DCM) #}
{% macro grant_app() -%}
  GRANT SELECT ON {{ 'VIEW' if config.get('materialized') == 'view' else 'TABLE' }} {{ this }}
    TO DATABASE ROLE {{ this.database }}.APP
{%- endmacro %}
