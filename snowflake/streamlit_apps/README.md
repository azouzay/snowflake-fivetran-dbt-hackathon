# Streamlit-in-Snowflake apps, declared as dbt exposures

**New for the hackathon.** Nothing in the base HOL repo, the Databricks field
enablement repo, or the fivetran-odi-agent-enablement-demo skill wires a BI
app into dbt as an exposure. This is that pattern, and it is the sharpest
proof point in the whole session: the same governed mart that feeds a Cortex
Agent (the AI surface) also feeds a small Streamlit app (the human surface),
and both show up together in the dbt DAG and dbt Catalog, hanging off the
same mart node. One definition, two consumers, one lineage graph.

---

## What's pre-built vs. what teams do

**Owner: pre-built before the day, same as the Cortex Agents in
`../cortex_semantic/agents_setup.md`.** Attendees do not create a Streamlit
app from scratch in a 2-3 hour session; they extend one that already exists
and already reads from their track's governed mart.

- **Pre-built:** the Streamlit object in Snowflake, its starter code (2-3 KPI
  tiles reading the mart or Semantic View directly), and the dbt exposure
  that declares it.
- **Team task, in session:** add one KPI tile or filter to the app. That is
  the scored stretch goal, not a blocking checkpoint — see the hackathon
  scoring rubric.

---

## The three pieces, per track

1. **`projects/<track>/streamlit_app/streamlit_app.py`** — the starter app,
   versioned in git like any other file in the track.
2. **`<track>_app_setup.md`** in this folder — the `CREATE STREAMLIT` DDL
   that deploys the file above into Snowflake, and the grants attendees need
   to open and edit it. Reference and verification here, not duplicated DDL
   living in two places, same convention as the Cortex Agent setup docs.
3. **A dbt exposure**, in `models/marts/_<track>__exposures.yml` in each
   track. `depends_on` points at the mart(s) the app queries, so the app
   becomes a node in the dbt DAG and shows up in dbt Catalog's lineage graph
   next to the Semantic View the Cortex Agent reads.

---

## Order of operations

Same shape as the Cortex Agent setup, and for the same reason: the mart has
to exist before anything downstream of it can be pointed at real data.

1. Run the dbt job at least once, so the track's headline mart(s) exist.
2. Upload `streamlit_app.py` to a Snowflake stage (see the per-track setup
   doc for the exact stage and path).
3. Run the `CREATE STREAMLIT` statement from the per-track setup doc.
4. Grant `USAGE` on the Streamlit app to `HOL_ATTENDEE`, and confirm the
   app's query warehouse role can read the mart it depends on.
5. Run `dbt build` (or at least `dbt parse`) again so the exposure resolves
   and appears in dbt Catalog.
6. Open the app signed in as an attendee-role user, not as ACCOUNTADMIN, and
   confirm the KPI tiles render.

---

## Why a dbt exposure, specifically

A dbt exposure does not deploy anything itself — it is metadata, a
declaration that "this downstream thing depends on these models." That is
exactly what the governance story needs: without it, the Streamlit app is
just another consumer nobody upstream knows about, the same problem the
Fivetran-to-dbt-to-AI story exists to solve in the first place. With it:

- The app appears in the dbt DAG and in dbt Catalog's lineage graph, next to
  the Semantic View.
- If a mart's contract changes, `dbt Cloud`/dbt Studio can show that the
  Streamlit app is a downstream consumer, the same way it would for another
  model.
- The room can see, in one graph, that the AI agent and the human app are
  reading the same governed definition, not two different ones somebody
  quietly forked.

---

## Extending to a new track

Copy `financial_services_app_setup.md` or `healthcare_pharma_app_setup.md`
as a starting point, and follow `docs/adding-an-industry.md`'s "wire it in"
step: a track is not done until its exposure is declared, same as its
Semantic View and its agent instructions.
