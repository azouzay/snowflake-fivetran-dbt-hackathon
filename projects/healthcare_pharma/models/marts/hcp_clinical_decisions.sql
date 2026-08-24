-- ---------------------------------------------------------------------------
-- hcp_clinical_decisions
--
-- The healthcare second mart: one row per patient clinical-decision record,
-- with cost, readmission-risk and outcome bands attached. This is where "are
-- clinical decisions sound" gets answered.
--
-- Contract enforced (see _healthcare_pharma__marts.yml). Contains no PHI
-- free-text: see the governance note in stg_cds_records.sql.
--
-- Grain: one row per record_id.
-- ---------------------------------------------------------------------------

{{ config(materialized='table') }}

with enriched as (

    select * from {{ ref('int_hcp_decisions_enriched') }}

)

select

    -- ---- keys ---------------------------------------------------------------
    cast(record_id as varchar) as record_id,
    cast(patient_id as varchar) as patient_id,

    -- ---- snapshot date, see int_hcp_decisions_enriched.sql ---------------------------
    cast(as_of_date as date) as as_of_date,

    -- ---- clinical dimensions ---------------------------------------------------
    cast(diagnosis as varchar) as diagnosis,
    cast(medical_conditions as varchar) as medical_conditions,
    cast(medication_adherence as varchar) as medication_adherence,
    cast(treatment_outcome as varchar) as treatment_outcome,
    cast(patient_satisfaction as varchar) as patient_satisfaction,

    -- ---- risk and outcome measures -----------------------------------------------
    cast(readmission_risk as number(9, 4)) as readmission_risk,
    cast(readmission_risk_level as varchar) as readmission_risk_level,
    cast(patient_outcome_score as number(9, 4)) as patient_outcome_score,
    cast(outcome_quality as varchar) as outcome_quality,
    cast(medical_error_rate as number(9, 4)) as medical_error_rate,
    cast(length_of_stay as number(38, 0)) as length_of_stay,
    cast(stay_category as varchar) as stay_category,

    -- ---- cost measures -----------------------------------------------------------
    cast(cost_of_care as number(18, 2)) as cost_of_care,
    cast(medication_cost as number(18, 2)) as medication_cost,
    cast(total_treatment_cost as number(18, 2)) as total_treatment_cost,
    cast(total_cost_savings as number(18, 2)) as total_cost_savings,
    cast(cost_efficiency as number(9, 4)) as cost_efficiency,

    -- ---- trial linkage (informational only) ----------------------------------------
    cast(clinical_trial_id as varchar) as clinical_trial_id,
    cast(trial_name as varchar) as trial_name,
    cast(trial_status as varchar) as trial_status,

    -- ---- flags -----------------------------------------------------------------
    cast(needs_review as boolean) as needs_review

from enriched
