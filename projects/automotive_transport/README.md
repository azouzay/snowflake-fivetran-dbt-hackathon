# Automotive & transport track — NOT YET BUILT

This folder is a copy of `projects/_template`, not a working track. Do not
put it in front of a room until the checklist below is done.

## Why it's not built

Every other track in this repo (`cpg`, `energy`, `financial_services`,
`healthcare_pharma`) was built by introspecting a real source schema first,
per `docs/adding-an-industry.md` Step 1, and every one of them turned up a
data surprise that shaped the design (energy's duplicate feed, financial
services' text-typed numerics, and so on). Nobody with warehouse access has
done that for this track yet.

There is also no schema in the source database that is actually
`automotive`. The 26-schema list in `docs/adding-an-industry.md` has one
plausible candidate: `transportation`. Whether it supports an "automotive"
story (fleet, vehicles, dealerships) or a broader "transportation and
logistics" one (shipping, routes, carriers) is unknown until someone queries
it. If the data turns out to support the latter better, rename this track to
**Transportation & logistics** rather than force an automotive story onto
data that does not have one — see the plan note that flagged this risk.

## What "done" looks like

Work through `docs/adding-an-industry.md` in full, in order:

1. **Introspect `transportation`** against the live Postgres source: columns
   and types, exact row counts, grain, every value of every categorical
   column, ranges, referential integrity, duplicate feeds, sentinel values.
   Write findings into `BUILD-NOTES.md`.
2. **Pick the business question** in one sentence, the way the other four
   tracks do. Likely shape, by analogy with the energy track's "what is our
   fleet costing us when it breaks": a reliability, cost, or delay-exposure
   story. Do not commit to this until Step 1 is done; the real data may
   suggest something better or rule this out.
3. **Build** staging → intermediate → marts → Semantic View, following the
   five rules in this folder's inherited `README.md` (from `_template`,
   still present below the placeholders — read it).
4. **Seed four bugs**, spread across independent DAG branches, none of them
   parse-time (see the swap table in `docs/facilitator-guide.md` if a
   wrong-column-name or contract-mismatch bug turns out to surface at parse
   once a live catalog connection exists).
5. **Wire it in**: `docs/answer-key.md`, a new
   `docs/attendee-guide-automotive-transport.md`, the top-level `README.md`
   track picker, `snowflake/cortex_semantic/agents_setup.md`, and
   `docs/facilitator-guide.md`.
6. **Dry run** end to end, exactly as an attendee would, against a live
   warehouse connection.

Budget close to a full day, more than the other new track
(`healthcare_pharma`) took, because there is no working model anywhere else
to adapt from — this one starts from raw SQL, not from a lift.

## Everything below this line is the unmodified template

See `projects/_template/README.md` for the full walkthrough, file-renaming
table, and the five rules that keep tracks interchangeable. This folder's
copies of `dbt_project.yml`, `models/`, and `tests/` still hold
`<track_key>` and `<...>` placeholders except where noted above; running
`dbt parse` against this folder will fail by design until they are filled
in, the same way `projects/_template` itself does not parse.
