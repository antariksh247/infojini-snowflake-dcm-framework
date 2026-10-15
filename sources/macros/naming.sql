{# Naming convention helpers: <PROJECT>_<ENV>_<LAYER>_DB, <PROJECT>_<ENV>_<PURPOSE>_WH #}
{% macro db(layer) -%}{{ project }}_{{ env }}_{{ layer }}_DB{%- endmacro %}
{% macro wh(purpose) -%}{{ project }}_{{ env }}_{{ purpose }}_WH{%- endmacro %}
