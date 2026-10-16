# infojini-snowflake-dcm-framework

Reusable CI/CD framework for Snowflake projects: **Snowflake DCM Projects** (platform objects) +
**dbt** (all tables and views) + **GitHub Actions** (promotion). Project code in this POC: `INFOJINI`.
Dummy data only.

> New to the repo? Read **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)**: how to build something and get it to PROD.

---

## Environments

| Env | What it is | Who changes it | How |
|---|---|---|---|
| **DEV** | Free playground, **not managed by DCM** | Data engineers, by hand | Worksheets (`CREATE OR REPLACE …`), workspace dbt `--target dev` |
| **STAGE** | Test environment, = branch `main` | CI user `INFOJINI_STAGE_CI_SVC` only | GitHub Actions on merge to `main` |
| **PROD** | Live, = latest release tag | CI user `INFOJINI_PROD_CI_SVC` only | GitHub Actions on tag `v*` + approval |

Bronze (`INFOJINI_BRONZE_DB`) is external (Fivetran / data share), shared and read-only for every env.

---

## Repo layout = Snowflake layout

```
manifest.yml                     environments (STAGE, PROD) and the values that differ per env
│
├── sources/definitions/         DCM — everything EXCEPT tables/views in Silver/Gold
│   ├── _environment/            warehouses.sql, access.sql (who gets READ/WRITE/APP per env)
│   ├── SILVER_DB/
│   │   ├── database.sql         database + access roles READ / WRITE
│   │   ├── STAGING/schema.sql
│   │   └── CORE/
│   │       ├── schema.sql
│   │       └── tasks/TSK_DBT_BUILD.sql
│   └── GOLD_DB/
│       ├── database.sql         database + access roles READ / WRITE / APP
│       ├── MART/schema.sql
│       └── APP/
│           ├── schema.sql
│           ├── tables/CUSTOMER_NOTES.sql
│           ├── sequences/NOTE_SEQ.sql
│           ├── procedures/SP_ADD_NOTE.sql
│           └── streamlit/STR_CUSTOMER_APP.sql
├── sources/macros/naming.sql    db('GOLD') -> INFOJINI_<ENV>_GOLD_DB, wh('TRANSFORM') -> INFOJINI_<ENV>_TRANSFORM_WH
│
├── dbt/                         dbt — ALL tables and views in Silver/Gold
│   └── models/
│       ├── SILVER_DB/STAGING/   stg_*.sql
│       └── GOLD_DB/
│           ├── MART/            dim_*.sql, fct_*.sql, v_*.sql
│           └── APP/             v_*.sql (read views for the app)
│
├── apps/STR_CUSTOMER_APP/       Streamlit code of GOLD_DB.APP.STR_CUSTOMER_APP
├── platform/                    one-time admin scripts (roles, CI users, Git, DEV playground)
├── pipeline/dbt_deploy.sql      dbt step used by GitHub Actions
└── .github/workflows/           01 test connection · 02 PR plan · 03 deploy STAGE · 04 deploy PROD
```

### Where is object X?

| Object | File |
|---|---|
| Table / view in Silver or Gold | `dbt/models/<DB>/<SCHEMA>/<name>.sql` |
| Procedure, function, task, sequence, app table, Streamlit | `sources/definitions/<DB>/<SCHEMA>/<type>/<NAME>.sql` |
| Database, its access roles | `sources/definitions/<DB>/database.sql` |
| Schema | `sources/definitions/<DB>/<SCHEMA>/schema.sql` |
| Warehouse, who gets access per env | `sources/definitions/_environment/` + `manifest.yml` |
| Streamlit code | `apps/<STREAMLIT_NAME>/` |
| Account roles, CI users, Git, DEV playground | `platform/` |

Example: `INFOJINI_PROD_GOLD_DB.APP.SP_ADD_NOTE` → `sources/definitions/GOLD_DB/APP/procedures/SP_ADD_NOTE.sql`

---

## Rules

1. **One owner per object.** Tables/views in Silver/Gold = dbt. Everything else = DCM. Never both.
2. **DCM never references dbt objects** (DCM deploys first). dbt may read DCM objects.
3. **One object per file, file name = object name.** Folder names have no environment in them.
4. **Only `manifest.yml` differs per environment.** No `DEV`/`STAGE`/`PROD` in object code — use `{{ db('…') }}` / `{{ wh('…') }}`.
5. **App data** (written by users) lives in DCM tables, never in dbt models (dbt rebuilds and would wipe it).
6. **Drops are blocked** on merge / tag. A reviewed drop is re-run manually with `allow_drops`.

## Naming

| Object | Pattern | Example |
|---|---|---|
| Database | `<PROJECT>_<ENV>_<LAYER>_DB` | `INFOJINI_PROD_GOLD_DB` |
| Warehouse | `<PROJECT>_<ENV>_<PURPOSE>_WH` | `INFOJINI_PROD_TRANSFORM_WH` |
| Functional role | `<PROJECT>_<FUNCTION>` | `INFOJINI_ANALYST` |
| Access role (database role) | `<DB>.READ` / `.WRITE` / `.APP` | `INFOJINI_PROD_GOLD_DB.READ` |
| Procedure / function / task / Streamlit | `SP_` / `FN_` / `TSK_` / `STR_` | `SP_ADD_NOTE` |
| dbt models | `stg_` / `int_` / `dim_` / `fct_` / `v_` | `fct_orders` |

## One-time platform setup (admin)

Run as ACCOUNTADMIN, in order: `platform/01_platform.sql` … `06_dev_playground.sql`
(+ `platform/poc/simulate_bronze.sql` in the POC only). Then create GitHub Environments
`INFOJINI_STAGE` and `INFOJINI_PROD` (PROD: required reviewer, tags `v*` only).
