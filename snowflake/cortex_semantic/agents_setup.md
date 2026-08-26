# Cortex Agents and Snowflake CoWork setup

**Owner: the Snowflake team. Done before the lab, not during it.**

Attendees consume these; they do not create them. Roughly 30 minutes of setup
the day before, plus one end-to-end test signed in as an attendee-role user.

---

## What you are building

One Cortex Agent per track, each pointed at the Semantic View that dbt creates,
surfaced in Snowflake CoWork at `ai.snowflake.com`.

| Track | Agent | Semantic View |
|---|---|---|
| Consumer packaged goods | `HOL_CPG_ANALYST` | `SV_CPG_COMMERCIAL_PERFORMANCE` |
| Energy | `HOL_ENERGY_ANALYST` | `SV_ENERGY_COMMODITY_PRICES` and `SV_ENERGY_EQUIPMENT_RELIABILITY` |
| Financial services | `HOL_FS_ANALYST` | `SV_FS_CREDIT_RISK` |
| Healthcare, pharma & life sciences | `HOL_HCP_ANALYST` | `SV_HCP_CLINICAL_TRIALS` and `SV_HCP_CLINICAL_DECISIONS` |

Energy's agent gets both of its Semantic Views as separate Cortex Analyst
tools. Commodity prices and equipment maintenance share no key, so they are two
objects; the agent routes between them based on the question. Healthcare,
pharma & life sciences is the same shape: pharma trials and healthcare
decisions share no key either.

**Healthcare, pharma & life sciences is not yet dry-run.** Its Semantic Views
parse clean on Fusion, but nobody has verified the categorical value lists in
the agent instructions below against a live Fivetran-landed copy of the
`pharma` and `healthcare` schemas. See `projects/healthcare_pharma/README.md`.

---

## Order of operations

This sequence matters, and getting it wrong is the most common reason the
agent looks broken.

1. Run `../reference_setup.sql` (database, warehouses, roles, grants).
2. Populate the instructor fallback schemas via Fivetran.
3. **Run the dbt job at least once.** The Semantic Views do not exist until
   dbt creates them, and you cannot point an agent at an object that is not
   there.
4. Apply the Semantic View grants from the per-track `*_semantic_view.sql`
   files.
5. Create the agents.
6. Test as an attendee-role user, not as ACCOUNTADMIN.

---

## Prerequisites

From [../GOTCHAS.md](../GOTCHAS.md) section 7, all four must be true:

- `SNOWFLAKE.CORTEX_USER` granted to `HOL_ATTENDEE` (or the narrower
  `SNOWFLAKE.CORTEX_AGENT_USER`, if the account deliberately withholds the rest
  of Cortex)
- Cortex models available in the account region, or
  `CORTEX_ENABLED_CROSS_REGION` set
- Snowflake CoWork enabled on the account
- If the account has a CoWork object, each agent added to it and `USAGE`
  granted on the object. Check with `SHOW SNOWFLAKE INTELLIGENCES`. Without
  this, the agents exist and simply do not appear in CoWork.

> **A note on the name.** Snowflake Intelligence was renamed **Snowflake
> CoWork**. The SQL identifiers did not change: the object type is still
> `SNOWFLAKE INTELLIGENCE`, and so are `ALLOWED_INTERFACES = (SNOWFLAKE_INTELLIGENCE)`
> and `LOGIN_IDP_REDIRECT`. Expect the old name in SQL and the new one in the UI.

---

## Creating an agent

In Snowsight, go to **AI & ML** then **Agents**, and create a new agent. Or use
SQL; either is fine, the UI is faster for three agents.

For each agent:

1. **Add a Cortex Analyst tool** and point it at the Semantic View. In Snowsight
   this is the **Tools** tab, then **+ Add** and **Semantic view**.
2. **Name the tool something a model can reason about.** `commodity_prices` and
   `equipment_maintenance` beat `tool_1` and `tool_2`, because the agent uses
   the tool name to decide where to send a question.
3. **Write agent instructions.** Use the per-track text below. This is the
   highest-leverage thing on the page: most "the agent gave a weird answer"
   problems in this lab are fixed by three lines of instruction, not by
   changing the model.
4. **Grant the agent to `HOL_ATTENDEE`.**

```sql
GRANT USAGE ON AGENT HOL_CPG_ANALYST TO ROLE HOL_ATTENDEE;

-- If the account has a CoWork object, the agent also has to be added to it or
-- it will not show up in CoWork at all.
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT HOL_SNOWFLAKE_INDUSTRY.<schema>.HOL_CPG_ANALYST;
```

---

## Agent instructions, per track

Paste these into the agent's instruction field. They exist because each track's
data has one or two properties that will otherwise produce answers that are
technically correct and practically wrong.

### Consumer packaged goods

```
You answer questions about consumer packaged goods commercial and inventory
performance.

When the user asks about revenue, sales, or how much money was made, use
total_recognised_revenue, not total_order_value. The two differ by about a
quarter: 192 of the 750 order lines are cancelled and still carry a value in
the raw feed. total_order_value includes those; total_recognised_revenue does
not. If the user explicitly asks for gross or booked value including
cancellations, use total_order_value and say that is what you did.

Order dates run from 2024-04-28 to 2024-12-31.

Stockout rate and overstock rate are shares between 0 and 1. Present them as
percentages.
```

### Energy

```
You answer questions about commodity prices and equipment maintenance. These
are two separate subject areas with no data in common. Never try to relate a
commodity price to a maintenance event.

Commodity prices run from 2000-01-04 to 2022-11-04 ONLY. There is no data after
November 2022. If the user asks about this year, recent prices, or the current
price, tell them the series ends in November 2022 and answer for the latest
period available instead of returning nothing.

WTI crude settled at -37.63 on 2020-04-20. That is a real market event, not a
data error. Do not filter it out or flag it as bad data.

Never average prices across different commodities. Gold is quoted per troy
ounce and sugar per pound; the average of the two is meaningless. Always group
by commodity or filter to one.

Maintenance events run from 2024-06-27 to 2026-07-16. Every maintenance figure
is computed on de-duplicated events: two source systems reported the same 750
events and the duplicates were removed upstream.

unplanned_work_rate is the headline reliability metric. Lower is better.
```

### Financial services

```
You answer questions about credit risk across a portfolio of customers and
lending institutions.

Risk scores are between 0 and 1, where higher means riskier. Present them to
two decimal places, not as percentages.

Monthly assessments run from 2022-01-01 to 2024-11-16.

total_risk_weighted_exposure is exposure multiplied by risk score. It is the
headline capital-at-risk figure and usually what someone means when they ask
"how much is at risk", as opposed to total_exposure which is the raw amount
lent.

You have no access to any customer name, email, social security number,
driver's licence, employer or postcode. That is deliberate. If asked for
information about a specific named individual, say that the data available to
you is de-identified and offer the segment-level answer instead.

Prefer institution_type, institution_size and region when describing where risk
sits. Only name a specific institution if the user asks for one directly.
```

### Healthcare, pharma & life sciences

```
You answer questions about two separate subject areas with no data in common:
pharma clinical trials, and healthcare clinical decisions. Never try to relate
a specific trial enrollment to a specific clinical decision record; the
clinical_trial_id field on clinical decisions is informational free text, not
a verified join key.

Trial risk score is between 0 and 100, where higher means more at risk.
Enrollment rate and dropout rate are percentages between 0 and 100.

Readmission risk and patient outcome score are between 0 and 1. Present them
to two decimal places, not as percentages.

You have no access to any patient's medical history, family medical history,
allergies, vital signs, genetic data, lab results, current medications,
medication recommendation, medication side effects, treatment plan, treatment
recommendation, or publication title. That is deliberate. If asked for any of
these, say that this data is not available to you and offer the diagnosis
category or outcome measures instead.

The categorical value lists (trial_status, disease_area, diagnosis,
medication_adherence, treatment_outcome, patient_satisfaction) have not yet
been confirmed against live data. If an answer seems to be missing an obvious
category, that is more likely an unconfirmed value list than a real gap; flag
it rather than stating a category does not exist.
```

---

## Sample questions

Give these to attendees as a starting point. They are chosen to work against
the real data, and each one has a known-good shape of answer.

### Consumer packaged goods

1. Which product categories have the highest stockout rate?
2. What is our total recognised revenue by product category?
3. What is the average order value for high-value customers compared with
   low-value customers?
4. How many products need planner review, and which categories are they in?
5. What is our cancellation rate, and does it differ by customer segment?
6. Which product categories have the best average product rating?
7. Show me average inventory turnover by product category, worst first.
8. Compare total order value with total recognised revenue by month.

Question 8 is the good one to demo. The gap between the two numbers is the
cancelled-order problem, and the agent will explain it if the instructions
above are in place.

### Energy

1. What was the average natural gas price in 2022?
2. Show me the Brent crude price trend through 2022.
3. Which commodity had the largest single-day loss, and when?
4. Which equipment has the highest maintenance cost?
5. What is our cost per hour of downtime by maintenance type?
6. What share of our maintenance work is unplanned?
7. Which technicians have the highest average downtime per job?
8. Compare average price and volatility across the energy complex in 2022.

Question 1 is the reliability check: ask "this year" instead and a
well-configured agent will tell you the data ends in 2022 rather than returning
an empty table. That is worth demonstrating deliberately.

### Financial services

1. Which customer segments have the highest average risk score?
2. Where is our risk-weighted exposure concentrated by institution type and
   region?
3. How has average risk score trended by quarter since 2022?
4. Which institution types have the highest anomaly rate?
5. What is the denial rate by income bracket?
6. Compare average credit score and average debt-to-income across customer
   segments.
7. Which product types carry the highest average exposure?
8. What is the average risk-adjusted return by institution risk appetite?

Then, as the governance beat, ask: **"What is the social security number of
customer CUST-C001?"** A correctly built agent cannot answer, because the
column is not in the mart, not in the Semantic View, and not grantable. That
is a better demonstration of governance than any slide.

### Healthcare, pharma & life sciences

1. Which disease areas have the highest average trial risk score?
2. How many trial enrollments are flagged as at risk, and in which disease
   areas?
3. What is the average dropout rate by sponsor?
4. Which diagnoses have the highest average readmission risk?
5. How many clinical decisions need review, and what share is that of the
   total?
6. What is the average patient outcome score by treatment outcome category?
7. Compare average cost of care and average cost efficiency across
   diagnoses.
8. Which age group has the highest average trial risk score?

Then, as the governance beat, ask: **"What is this patient's medical
history?"** or **"Show me the genetic data for record R-0001."** A correctly
built agent cannot answer either, because neither column is in the mart, in
the Semantic View, or grantable. Same beat as financial services asking for a
social security number, on a different kind of sensitive data.

---

## Troubleshooting

**Agent returns nothing at all, no error.**
Almost always a missing grant. Check two things, in this order: `REFERENCES` as
well as `SELECT` on the Semantic View, then `SELECT` on the tables underneath it.
An agent using a Semantic View needs base-table access even though a plain SQL
query against the same view would not — see [../GOTCHAS.md](../GOTCHAS.md)
section 8. Check the `GRANT` statements in the per-track file.

**Agent does not appear in CoWork at all.**
Different failure, different cause. If the account has a CoWork object, the agent
has to be added to it. `SHOW SNOWFLAKE INTELLIGENCES` tells you whether one
exists.

**Agent worked yesterday, does not today.**
The dbt job ran and `CREATE OR REPLACE SEMANTIC VIEW` dropped the object along
with every grant on it. Re-run the grants, or set `create_or_alter=true` in the
dbt model config. See [../GOTCHAS.md](../GOTCHAS.md) section 8.

**"Semantic view does not exist."**
The dbt job has not run, or it ran into a different target schema than the one
the agent points at. Check with `SHOW SEMANTIC VIEWS IN DATABASE
HOL_SNOWFLAKE_INDUSTRY`.

**Cortex errors about model availability.**
Region problem. See [../GOTCHAS.md](../GOTCHAS.md) section 7 and set
`CORTEX_ENABLED_CROSS_REGION`.

**Answers are plausible but wrong.**
Check the agent instructions are actually saved. The revenue-versus-order-value
trap in CPG and the date-range trap in energy both produce confident wrong
answers when the instruction text is missing.

**It works for you and not for attendees.**
You are testing as ACCOUNTADMIN. Always retest with a user whose only role is
`HOL_ATTENDEE`.

---

## The other half of the consumption story

This page covers the Snowflake-native path: metrics defined in a Snowflake
Semantic View, read by Cortex Analyst.

The other path is metrics defined in the dbt Semantic Layer and served through
the dbt MCP Server. Registering that server directly inside Snowflake
Intelligence does not currently work: Snowflake's external MCP connectors
require OAuth with a client secret, and dbt's remote MCP server issues public
clients using PKCE. Nothing is required from the Snowflake side to work around
it.

The full explanation, with citations and a path that works today, is in
[../../docs/dbt-mcp-on-snowflake-cowork.md](../../docs/dbt-mcp-on-snowflake-cowork.md).
