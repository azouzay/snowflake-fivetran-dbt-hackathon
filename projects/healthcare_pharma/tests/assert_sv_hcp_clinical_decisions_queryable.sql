-- Singular test: the sv_hcp_clinical_decisions semantic view must compile and
-- return data. See assert_sv_hcp_clinical_trials_queryable.sql for why this
-- cannot be a plain SELECT.

with sv as (
    select count(*) as record_count
    from SEMANTIC_VIEW({{ ref('sv_hcp_clinical_decisions') }} DIMENSIONS CLINICAL_DECISIONS.DIAGNOSIS)
)
select * from sv where record_count = 0
