# infojini-snowflake-dcm-framework

Reusable CI/CD framework for Snowflake projects using **Snowflake DCM Projects** + **dbt** + **GitHub Actions**.
Project code in this POC: `INFOJINI`. Dummy data only.

## Environments

| Env | Purpose | Deployed by | How |
|---|---|---|---|
| DEV | Development playground | Data engineers (`INFOJINI_DEV_DEPLOYER`) | Snowsight Workspace: Plan / Deploy |
| STAGE | Final testing / UAT, equals `main` | CI service user only (`INFOJINI_STAGE_DEPLOYER`) | GitHub Actions on merge to `main` |
| PROD | Live, equals the latest release tag | CI service user only (`INFOJINI_PROD_DEPLOYER`) | GitHub Actions on tag + approval |

Bronze (`INFOJINI_BRONZE_DB`) is an external, shared source (Fivetran / data share in real projects).
It is read-only for every environment and not managed by DCM. In this POC it is simulated by a script.

## Repo layout

```
setup/          admin, once: platform, Git + CI user, Bronze access
scripts/        POC helpers: simulate Bronze, validation
manifest.yml    DCM targets INFOJINI_DEV / INFOJINI_STAGE / INFOJINI_PROD + variables
sources/
  definitions/  DEFINE statements: databases, schemas, roles, grants, procs, views, tasks, Streamlit
  macros/       Jinja helpers (naming)
  dbt/          dbt project (Silver / Gold models)
post_deploy/    what DCM can't do yet (e.g. attach masking policies)
.github/        GitHub Actions workflows
```

## Naming convention

| Object | Pattern | Example |
|---|---|---|
| Env database | `<PROJECT>_<ENV>_<LAYER>_DB` | `INFOJINI_PROD_GOLD_DB` |
| Shared Bronze | `<PROJECT>_BRONZE_DB` | `INFOJINI_BRONZE_DB` |
| Warehouse | `<PROJECT>_<ENV>_<PURPOSE>_WH` | `INFOJINI_STAGE_TRANSFORM_WH` |
| Functional role | `<PROJECT>_<FUNCTION>` | `INFOJINI_ANALYST` |
| System role | `<PROJECT>_<ENV>_<PURPOSE>` | `INFOJINI_PROD_DEPLOYER` |
| Database role | `READ` / `WRITE` | `INFOJINI_PROD_GOLD_DB.READ` |
| Procedure / function / view / task | `SP_` / `FN_` / `V_` / `TSK_` | `SP_LOAD_PATIENTS` |

## POC steps

| Step | What | Run |
|---|---|---|
| 1 | Platform: roles, admin DB, warehouses, DCM project objects | `setup/01_platform.sql` as ACCOUNTADMIN |
| 2 | Git connection (API integration + Git repository object) | `setup/02_git.sql` as ACCOUNTADMIN |
| 3 | Simulated Bronze + read access | coming |
| 4 | First DCM deploy to DEV (minimal) | coming |
| 5 | Procs, functions, views, task, app | coming |
| 6 | dbt | coming |
| 7 | GitHub Actions: PR plan, STAGE, PROD | coming |
| 8 | Change / rollback / drop-protection tests | coming |
