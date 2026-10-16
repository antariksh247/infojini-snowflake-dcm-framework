-- WHO gets WHAT in this environment.
-- Functional (account) roles  ->  access (database) roles READ / WRITE / APP.
-- The lists come from manifest.yml (templating -> configurations -> STAGE / PROD).
-- The database roles themselves are defined in <DB>/database.sql.

{% for r in silver_write %}GRANT DATABASE ROLE {{ db('SILVER') }}.WRITE TO ROLE {{ r }};
{% endfor %}
{% for r in silver_read %}GRANT DATABASE ROLE {{ db('SILVER') }}.READ TO ROLE {{ r }};
{% endfor %}
{% for r in gold_write %}GRANT DATABASE ROLE {{ db('GOLD') }}.WRITE TO ROLE {{ r }};
{% endfor %}
{% for r in gold_read %}GRANT DATABASE ROLE {{ db('GOLD') }}.READ TO ROLE {{ r }};
{% endfor %}
{% for r in app_users %}GRANT DATABASE ROLE {{ db('GOLD') }}.APP TO ROLE {{ r }};
{% endfor %}

-- Warehouse usage for everyone who gets data access in this environment
{% for r in (silver_write + silver_read + gold_write + gold_read + app_users) | unique %}GRANT USAGE ON WAREHOUSE {{ wh('TRANSFORM') }} TO ROLE {{ r }};
{% endfor %}
