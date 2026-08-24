# Healthcare, pharma & life sciences: Streamlit app setup

**Owner: the Snowflake team. Done before the day, not during it.** Same
timing as `../cortex_semantic/agents_setup.md`.

Reference and verification here, not duplicated app code: the app itself is
`../../projects/healthcare_pharma/streamlit_app/streamlit_app.py`.

---

## Prerequisites

- The dbt job has run at least once in production, so `hcp_clinical_trials`
  and `hcp_clinical_decisions` exist.
- Same open item as everywhere else in this track: the `healthcare` and
  `pharma` schemas have not been introspected against a live Fivetran sync
  yet. This app will run against whatever the marts actually contain once
  they exist; verify the tiles show sane numbers during step 4 below rather
  than assuming they will.

## 1. Create a stage and upload the app file

```sql
USE ROLE HOL_DBT;
USE DATABASE HOL_SNOWFLAKE_INDUSTRY;

CREATE STAGE IF NOT EXISTS hol_streamlit_apps
    DIRECTORY = (ENABLE = TRUE);
```

(If the financial services app already created this stage, skip straight to
uploading — one stage can hold every track's app under its own path.)

```sql
PUT file:///path/to/projects/healthcare_pharma/streamlit_app/streamlit_app.py
    @hol_streamlit_apps/healthcare_pharma/
    AUTO_COMPRESS = FALSE
    OVERWRITE = TRUE;
```

## 2. Create the Streamlit object

```sql
CREATE OR REPLACE STREAMLIT hol_hcp_trial_outcomes_dashboard
    ROOT_LOCATION = '@hol_snowflake_industry.public.hol_streamlit_apps/healthcare_pharma'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = HOL_DBT_WH;
```

## 3. Grant attendee access

```sql
GRANT USAGE ON STREAMLIT hol_hcp_trial_outcomes_dashboard TO ROLE HOL_ATTENDEE;

GRANT SELECT ON TABLE hcp_clinical_trials TO ROLE HOL_ATTENDEE;
GRANT SELECT ON TABLE hcp_clinical_decisions TO ROLE HOL_ATTENDEE;
```

Same re-grant-after-every-job caveat as the financial services setup doc,
step 3.

## 4. Verify

Open the app signed in as a `HOL_ATTENDEE`-only user. Confirm both tabs
render. If a tile shows an unexpected number or an empty chart, that is more
likely the unconfirmed data (see Prerequisites) than a broken app; note it
in `BUILD-NOTES.md` rather than silently adjusting the query to hide it.

## 5. Confirm the exposure resolved

```bash
dbt build   # or, at minimum, dbt parse
```

Then check dbt Catalog: `hcp_trial_and_outcomes_dashboard` should appear as
a downstream node off `hcp_clinical_trials` and `hcp_clinical_decisions`, in
the same lineage graph as `sv_hcp_clinical_trials` and
`sv_hcp_clinical_decisions`.

---

## Troubleshooting

See `financial_services_app_setup.md`'s troubleshooting section; the same
three failure shapes apply (bad stage path, missing grants, grants dropped
by a rebuild).
