# Hackathon format

This fork turns the base 2-hour guided lab into a 2.5-3 hour scored team
competition at Snowflake's offices, for prospects and customers. It reuses
the base lab's checkpoint structure almost entirely; this page covers what
changed and why.

For the plain guided-lab format, see the parent repo,
[snowflake-fivetran-dbt-hol](https://github.com/hicham-bab/snowflake-fivetran-dbt-hol).

---

## What changed from the base lab

- **Teams, not individuals.** Attendees self-select a track by industry fit,
  then form teams within it, rather than each forking and working solo.
- **A scoreboard, not just checkpoints.** The same checkpoints still gate
  progress (staging green, then a green production job), but now feed a
  points total instead of just marking "done."
- **A fourth module: the Streamlit app.** Each track ships a pre-built
  Streamlit-in-Snowflake app, declared as a dbt exposure. The in-session
  task is to extend it with one KPI tile or filter — see
  [snowflake/streamlit_apps/README.md](snowflake/streamlit_apps/README.md).
- **A fifth track was added, and a sixth attempted.** Healthcare, pharma &
  life sciences is new and not yet dry-run. Automotive & transport was
  attempted and is not yet built; see its README before offering it as a
  choice on the day.

---

## Scoring rubric

One rubric, applied identically across every track, so a single cross-track
leaderboard is meaningful even though the content differs.

| Item | Points | Notes |
|---|---|---|
| Checkpoint 1: `dbt build --select staging` green | Gate, not scored | Must pass to continue. Everyone gets here via the instructor fallback schema if their own sync is slow |
| Each seeded bug fixed correctly | 10 each (40 total) | Wrong-fix-that-compiles counts as unfixed even if the build goes green — check the diff, not just the build status |
| Opened and compared both semantic-layer definitions | 10 | Snowflake Semantic View and dbt Semantic Layer, same metric, side by side |
| Green production job, dbt Catalog populated | 15 | The second hard gate in the base lab, carried over unchanged |
| Correctly answered 3 of the 8 sample questions via Cortex Analyst / Snowflake CoWork | 15 | Pick 3 from the track's list in `snowflake/cortex_semantic/agents_setup.md` |
| Streamlit exposure stretch goal: one new tile or filter shipped | 10 (bonus) | Not required to finish; rewards teams who get through the rest early |
| Time to first green production job | Tiebreaker only | Never worth more than the accuracy items above |

Maximum core score: 80. Plus up to 10 bonus. Ties break on time.

**Do not let the scoreboard override the teaching moments.** The two
pull-the-room-together moments in `docs/facilitator-guide.md` (energy bug
02's silent grain change, financial services bug 02's wrong-fix-that-compiles)
are worth pausing the clock for. A team that fixes a bug the wrong way and
gets full marks because the build went green has missed the point of the
exercise; award points based on the diff, not the exit code.

---

## Timing table

Extends the base lab's table in `docs/agenda.md` by roughly 30-45 minutes:
+15-20 min for the Streamlit module, +10 min for a scoreboard reveal at the
end, and a little slack built into the earlier sections given the larger,
more industry-diverse room.

| Clock | Section | Min | Gate |
|---|---|---|---|
| 0:00 | Welcome, form teams, pick a track | 10 | Every team has picked and forked |
| 0:10 | Fivetran connector, start sync | 15 | Sync started, or fallback taken |
| 0:25 | dbt platform setup, sources, staging | 15 | **Checkpoint 1 green** |
| 0:40 | dbt Studio and Fusion tour | 8 | |
| 0:48 | dbt Wizard, four bugs, one model | 25 | At least two bugs fixed |
| 1:13 | Semantic layer, two ways | 10 | Both definitions opened |
| 1:23 | Production job, docs, dbt State | 8 | **Job succeeded in production** |
| 1:31 | dbt Catalog tour | 8 | Catalog is populated |
| 1:39 | Ask your data | 18 | 3 questions answered correctly |
| 1:57 | Streamlit module: extend the app | 18 | One tile or filter added, or skipped as a stretch |
| 2:15 | Wrap, scoreboard reveal, pull request | 10 | |
| 2:25 | End (2:25-3:00 buffer for a larger, more varied room) | | |

If the room runs long, the Streamlit module is the one to compress first —
it is explicitly a stretch goal, not a gate.

---

## Facilitator logistics

Reuse everything in `docs/facilitator-guide.md` as written: the fallback
schema philosophy, the pre-flight checklist, the mandatory dry run three
days out, and the room-logistics tables for steering people to a track.
Two additions for this format:

- **Fallback schemas for the two new tracks:** `hicham_bab_pharma`,
  `hicham_bab_healthcare`, and (once built) `hicham_bab_transportation`,
  populated and readable as the dbt role, same as the other three.
- **Streamlit app setup** happens on the same "two days before" timeline as
  the Cortex Agent setup, per `snowflake/streamlit_apps/README.md`.

**Do not offer automotive & transport as a track choice** until its README
no longer says NOT YET BUILT.
