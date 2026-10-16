# Developer guide

How to build something in Snowflake and get it to PROD.

```
1. BUILD in DEV        → like always: worksheets, real names, run and check
2. COPY into the repo  → right folder, CREATE → DEFINE, DEV name → {{ db('…') }}
3. PR                  → GitHub shows the STAGE plan as a comment
4. MERGE               → STAGE is deployed automatically (DCM, then dbt)
5. RELEASE             → tag vX.Y.Z + approval → PROD
```

---

## 1. Build in DEV (free playground)

DEV is **not** managed by DCM. Use role `INFOJINI_DATA_ENGINEER` and create anything:

```sql
USE ROLE INFOJINI_DATA_ENGINEER;
USE WAREHOUSE INFOJINI_DEV_TRANSFORM_WH;

CREATE OR REPLACE PROCEDURE INFOJINI_DEV_GOLD_DB.APP.SP_CLOSE_NOTE(P_NOTE_ID NUMBER) ...;
CALL INFOJINI_DEV_GOLD_DB.APP.SP_CLOSE_NOTE(1);     -- test it for real
```

**Tables and views in Silver/Gold → write them as dbt models**, not by hand:
in the Snowsight workspace open `dbt/`, add the `.sql` file, then **Run** / **Build** with target **`dev`**
(or **Preview** to see the result without creating anything).

## 2. Copy into the repo

### Which folder?

| You built a… | Put it in |
|---|---|
| table / view in Silver or Gold | `dbt/models/<DB>/<SCHEMA>/<name>.sql` (just the `SELECT`) |
| procedure | `sources/definitions/<DB>/<SCHEMA>/procedures/<NAME>.sql` |
| function | `sources/definitions/<DB>/<SCHEMA>/functions/<NAME>.sql` |
| task | `sources/definitions/<DB>/<SCHEMA>/tasks/<NAME>.sql` |
| app table (user-entered data) | `sources/definitions/GOLD_DB/APP/tables/<NAME>.sql` |
| Streamlit app | code in `apps/<NAME>/`, object in `sources/definitions/GOLD_DB/APP/streamlit/<NAME>.sql` + asset in `manifest.yml` |
| new schema | `sources/definitions/<DB>/<SCHEMA>/schema.sql` (+ folder in `dbt/dbt_project.yml` if dbt uses it) |

### What to change (only 2 things)

| In DEV you wrote | In the repo file |
|---|---|
| `CREATE OR REPLACE PROCEDURE` / `TABLE` / `TASK` … | `DEFINE PROCEDURE` / `TABLE` / `TASK` … |
| `INFOJINI_DEV_GOLD_DB` | `{{ db('GOLD') }}` |
| `INFOJINI_DEV_SILVER_DB` | `{{ db('SILVER') }}` |
| `INFOJINI_DEV_TRANSFORM_WH` | `{{ wh('TRANSFORM') }}` |

Everything else (logic, columns, procedure body) stays exactly the same.
Add the grants the object needs at the bottom of the same file. Example:

```sql
-- Procedure GOLD_DB.APP.SP_CLOSE_NOTE(note_id) : marks a note as closed.

DEFINE PROCEDURE {{ db('GOLD') }}.APP.SP_CLOSE_NOTE(P_NOTE_ID NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  UPDATE {{ db('GOLD') }}.APP.CUSTOMER_NOTES SET NOTE = NOTE || ' [closed]' WHERE NOTE_ID = :P_NOTE_ID;
  RETURN 'OK';
END;
$$;

GRANT USAGE ON PROCEDURE {{ db('GOLD') }}.APP.SP_CLOSE_NOTE(NUMBER) TO DATABASE ROLE {{ db('GOLD') }}.APP;
```

dbt models need no change at all: the target (`dev` / `stage` / `prod`) picks the database.
New dbt model → also add tests in the folder's `_models.yml` (at least `unique` + `not_null` on the key).

Tip: Cortex Code can do the conversion: *"Convert this procedure to a DCM DEFINE file for this repo
(replace INFOJINI_DEV_GOLD_DB with {{ db('GOLD') }})"*.

## 3. Pull request

Branch → commit → PR to `main`. Workflow **02 PR plan** comments the **STAGE plan** on the PR:
what will be created / altered / dropped. Syntax errors and missing objects show up here.
Reviewer checks the code **and** the plan.

## 4. Merge → STAGE

**03 Deploy STAGE** runs automatically: DCM deploy, then dbt build. Test in STAGE.
- Plan contains a DROP of a database / schema / table / stage → the deploy is **blocked**.
  If the drop is intended: Actions → 03 Deploy STAGE → Run workflow → `main` → tick `allow_drops`.

## 5. Release → PROD

GitHub → Releases → new tag `vX.Y.Z` on `main` → Publish → approve **04 Deploy PROD**.
Drops: Run workflow → **Use workflow from: tag** `vX.Y.Z` → tick `allow_drops` → approve.

---

## Don'ts

- Don't create objects by hand in STAGE / PROD (you can't — only the CI users can).
- Don't put a table/view in both dbt and DCM.
- Don't reference a dbt model from a DCM view / procedure.
- Don't hard-code `DEV` / `STAGE` / `PROD` names in repo files or Streamlit code
  (Streamlit: use `CURRENT_DATABASE()`).
