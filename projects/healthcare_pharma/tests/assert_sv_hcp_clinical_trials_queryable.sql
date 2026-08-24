-- Singular test: the sv_hcp_clinical_trials semantic view must compile and
-- return data. Snowflake semantic views cannot be queried with a plain
-- SELECT (generic tests fail with "Invalid object type: 'TABLE'"), so this
-- uses the SEMANTIC_VIEW() query syntax. Fails when the view is empty or
-- unqueryable.

with sv as (
    select count(*) as record_count
    from SEMANTIC_VIEW({{ ref('sv_hcp_clinical_trials') }} DIMENSIONS CLINICAL_TRIALS.DISEASE_AREA)
)
select * from sv where record_count = 0
