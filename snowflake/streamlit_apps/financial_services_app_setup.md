# Financial services: Streamlit app setup

**Owner: the Snowflake team. Done before the day, not during it.** Same
timing as `../cortex_semantic/agents_setup.md`: the marts have to exist
before this can point at real data.

Reference and verification here, not duplicated app code: the app itself is
`../../projects/financial_services/streamlit_app/streamlit_app.py`.

---

## Prerequisites

- The dbt job has run at least once in production, so `fs_risk_relationship_summary`
  and `fs_monthly_risk_assessment` exist.
- A schema to hold the app object. Reuse the schema the track's marts land
  in, or a dedicated `HOL_APPS` schema; either works, but the app's query
  role needs `SELECT` on the marts either way.

## 1. Create a stage and upload the app file

```sql
USE ROLE HOL_DBT;
USE DATABASE HOL_SNOWFLAKE_INDUSTRY;

CREATE STAGE IF NOT EXISTS hol_streamlit_apps
    DIRECTORY = (ENABLE = TRUE);
```

Upload `streamlit_app.py` to the stage. Easiest from Snowsight: **Data →
Databases → HOL_SNOWFLAKE_INDUSTRY → Stages → HOL_STREAMLIT_APPS → +
Files**, into a `financial_services/` path. From SnowSQL:

```sql
PUT file:///path/to/projects/financial_services/streamlit_app/streamlit_app.py
    @hol_streamlit_apps/financial_services/
    AUTO_COMPRESS = FALSE
    OVERWRITE = TRUE;
```

## 2. Create the Streamlit object

```sql
CREATE OR REPLACE STREAMLIT hol_fs_credit_risk_dashboard
    ROOT_LOCATION = '@hol_snowflake_industry.public.hol_streamlit_apps/financial_services'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = HOL_DBT_WH;
```

Adjust the schema in `ROOT_LOCATION` to wherever the stage actually lives if
not `public`.

## 3. Grant attendee access

```sql
GRANT USAGE ON STREAMLIT hol_fs_credit_risk_dashboard TO ROLE HOL_ATTENDEE;

-- The app queries the marts directly, so the role it runs as needs read
-- access on them. If attendees open the app under their own role rather
-- than a shared service role, this grant has to reach HOL_ATTENDEE too, on
-- top of whatever the dbt job already grants.
GRANT SELECT ON TABLE fs_risk_relationship_summary TO ROLE HOL_ATTENDEE;
GRANT SELECT ON TABLE fs_monthly_risk_assessment TO ROLE HOL_ATTENDEE;
```

If a `dbt build` re-creates these tables (`CREATE OR REPLACE TABLE` is the
default materialization behaviour), the grants above get dropped with them,
same gotcha as the Semantic View grants in
`../cortex_semantic/agents_setup.md`. Re-run this step after every
production job, or set `create_or_alter=true` on the mart configs. See
`../GOTCHAS.md` section 8.

## 4. Verify

Open the app from Snowsight (**Projects → Streamlit**) signed in as a user
whose only role is `HOL_ATTENDEE`, not as ACCOUNTADMIN. Confirm all three
tiles and both charts render with real numbers.

## 5. Confirm the exposure resolved

```bash
dbt build   # or, at minimum, dbt parse
```

Then check dbt Catalog: `fs_credit_risk_dashboard` should appear as a
downstream node off `fs_risk_relationship_summary` and
`fs_monthly_risk_assessment`, in the same lineage graph as
`sv_fs_credit_risk`.

---

## Troubleshooting

**"Object does not exist" opening the app.**
The stage path in `ROOT_LOCATION` is wrong, or the file was never uploaded.
`LIST @hol_streamlit_apps/financial_services;` to check.

**App opens but tiles show an error instead of a number.**
Missing `SELECT` grant on one of the marts for the role the app runs as.
Same failure shape as the Cortex Agent's "returns nothing" symptom, same
fix: check the grants, not the code.

**App worked yesterday, breaks today.**
The dbt job re-created the marts and dropped the grants. See step 3.
