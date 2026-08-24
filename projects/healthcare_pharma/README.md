# Healthcare, pharma & life sciences track

Two subject areas from one Fivetran source: pharma clinical trial risk, and
healthcare clinical decisions. They share no key, so this track has two
headline marts and two Semantic Views instead of one joined view.

The full step-by-step walkthrough belongs in
`docs/attendee-guide-healthcare-pharma.md` (not yet written; copy an existing
attendee guide and adapt, per `docs/adding-an-industry.md` Step 5).

## Status: not yet dry-run

This track's staging and intermediate SQL is adapted from a working dbt
project against the same underlying "industry" fixture database, so the
logic itself is proven elsewhere. What has **not** happened yet:

- Step 1 of `docs/adding-an-industry.md` (introspect the live `healthcare`
  and `pharma` schemas through this track's own Fivetran connector) has not
  been run. Column value lists, exact row counts and ranges below are
  carried over from the other project, not re-verified here.
- `dbt build` has not been run against a live warehouse.
- The four seeded bugs are deliberately restricted to contract-test config
  (`accepted_values` and `dbt_utils.accepted_range`) rather than the fuller
  spread across intermediate SQL, mart SQL, mart test and mart contract that
  the other three tracks use, specifically to avoid the parse-time risk
  documented in `docs/facilitator-guide.md` ("the one check that actually
  matters: when do the bugs surface"). Once Step 1 and a live dry run are
  done, consider swapping one or two for a data-dependent bug for variety.

Do not put this in front of a room until the checklist in
`docs/adding-an-industry.md` Step 6 is complete.

## Who should pick this track

Pick it if healthcare, pharma or life sciences is your business, or if you
want two independent stories instead of one five-table star. It is not
harder or easier than the other tracks by design; nobody is scoring track
choice.

## The business question

> Which trials are at risk, are clinical decisions sound, and can an AI agent
> surface both without exposing protected health information?

## Quickstart

1. Open this folder (`projects/healthcare_pharma`) in dbt Studio.
2. Edit `dbt_project.yml` and set `pharma_source_schema` and
   `healthcare_source_schema` to your own Fivetran destination schemas.
3. `dbt deps`
4. `dbt build --select staging`, which is checkpoint 1 and should be green.
5. `dbt build`, which is where the seeded bugs live. Fix them with dbt Wizard.

Stuck? Set both schema vars back to `hicham_bab_pharma` and
`hicham_bab_healthcare` in `dbt_project.yml` and everything works against the
instructor's data.

## The two subject areas

```
pharma.phr_records ──> stg_phr_records ──> int_hcp_trials_enriched ──> hcp_clinical_trials ──> sv_hcp_clinical_trials
                                                                              (pipeline risk: is a trial stalling)

healthcare.cds_records ──> stg_cds_records ──> int_hcp_decisions_enriched ──> hcp_clinical_decisions ──> sv_hcp_clinical_decisions
                                                                              (patient risk: is a decision sound)
```

`clinical_trial_id` and `trial_name`/`trial_status` on `hcp_clinical_decisions`
are informational free text carried from the source, not an enforced foreign
key back to `hcp_clinical_trials`. Do not join the two marts as though they
share a verified key; that has not been checked.

## The governance beat

`cds_records` has eleven free-text or narrative-shaped columns that carry
real protected-health-information risk: `medical_history`,
`family_medical_history`, `allergies`, `vital_signs`, `genetic_data`,
`lab_results`, `current_medications`, `medication_recommendation`,
`medication_side_effects`, `treatment_plan`, `treatment_recommendation`, and
`publication_title`. None of them reach `stg_cds_records`.

This is the same call the financial services track makes on `loan`:
exclude-then-justify, not the other way round. `diagnosis` is exposed because
it is a controlled clinical driver the story needs, the same way FS exposes
`credit_score_range` rather than a name.

**Contracts are the enforcement.** Both marts have `contract: enforced: true`
with the full column list pinned in `_healthcare_pharma__marts.yml`. Add one
of the eleven columns back upstream and the build fails with a named column,
before anything is written.

The live-room moment to land this: ask the Cortex Agent for a patient's
medical history or genetic data. It cannot answer, because the column does
not exist. Same beat as financial services asking for a social security
number.

## Headline metrics

**Pharma:** average trial risk score, average enrollment rate, average
dropout rate, enrollment count, at-risk count and rate. Sliced by disease
area, sponsor, trial status, regulatory approval status, age group and
gender.

**Healthcare:** average readmission risk, average outcome score, average
medical error rate, total treatment cost, average cost efficiency, decision
count, needs-review count and rate. Sliced by diagnosis, medication
adherence, treatment outcome, patient satisfaction, readmission risk level,
outcome quality and stay category.
