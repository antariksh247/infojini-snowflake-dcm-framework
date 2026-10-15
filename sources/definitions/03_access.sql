-- Access roles = database roles READ / WRITE per database (WRITE includes READ).
-- Functional (account) roles get them per env, from the lists in manifest.yml.

{% for layer in ['SILVER', 'GOLD'] %}
DEFINE DATABASE ROLE {{ db(layer) }}.READ  COMMENT = 'Read all data in {{ db(layer) }}';
DEFINE DATABASE ROLE {{ db(layer) }}.WRITE COMMENT = 'Read + DML on all tables in {{ db(layer) }}';

GRANT DATABASE ROLE {{ db(layer) }}.READ TO DATABASE ROLE {{ db(layer) }}.WRITE;
GRANT USAGE ON DATABASE {{ db(layer) }} TO DATABASE ROLE {{ db(layer) }}.READ;
{% endfor %}

GRANT USAGE ON SCHEMA {{ db('SILVER') }}.CORE    TO DATABASE ROLE {{ db('SILVER') }}.READ;
GRANT USAGE ON SCHEMA {{ db('SILVER') }}.STAGING TO DATABASE ROLE {{ db('SILVER') }}.READ;
GRANT USAGE ON SCHEMA {{ db('GOLD') }}.MART   TO DATABASE ROLE {{ db('GOLD') }}.READ;
GRANT USAGE ON SCHEMA {{ db('GOLD') }}.APP    TO DATABASE ROLE {{ db('GOLD') }}.READ;

-- Database role -> functional role, per environment
{% for r in silver_write %}GRANT DATABASE ROLE {{ db('SILVER') }}.WRITE TO ROLE {{ r }};
{% endfor %}
{% for r in silver_read %}GRANT DATABASE ROLE {{ db('SILVER') }}.READ TO ROLE {{ r }};
{% endfor %}
{% for r in gold_write %}GRANT DATABASE ROLE {{ db('GOLD') }}.WRITE TO ROLE {{ r }};
{% endfor %}
{% for r in gold_read %}GRANT DATABASE ROLE {{ db('GOLD') }}.READ TO ROLE {{ r }};
{% endfor %}

-- Warehouse usage for everyone who gets data access in this env
{% for r in (silver_write + silver_read + gold_write + gold_read + app_users) | unique %}GRANT USAGE ON WAREHOUSE {{ wh('TRANSFORM') }} TO ROLE {{ r }};
{% endfor %}
