{# Post-hook: SELECT on the model to the database role <DB>.READ (created by DCM) #}
{% macro grant_read() -%}
  GRANT SELECT ON {{ 'VIEW' if config.get('materialized') == 'view' else 'TABLE' }} {{ this }}
    TO DATABASE ROLE {{ this.database }}.READ
{%- endmacro %}
