-- ---------------------------------------------------------------------------
-- stg_cds_records
--
-- One row per patient clinical-decision record.
--
-- GOVERNANCE NOTE
-- The source has eleven free-text or narrative-shaped columns that carry real
-- protected-health-information risk: medical_history, family_medical_history,
-- allergies, vital_signs, genetic_data, lab_results, current_medications,
-- medication_recommendation, medication_side_effects, treatment_plan,
-- treatment_recommendation, and publication_title. None of them appear below.
--
-- This track makes the same call the financial services track makes on
-- `loan`: exclude-then-justify, not the other way round. A category like
-- `diagnosis` is exposed because it is a controlled clinical driver the story
-- needs (and is treated the same way FS exposes `credit_score_range` rather
-- than a name). Free-text clinical narrative is excluded because an AI agent
-- will read it back verbatim to whoever asks, and nothing downstream of this
-- model needs the narrative itself, only the structured measures next to it.
--
-- Verify the categorical value lists below (diagnosis, medication_adherence,
-- treatment_outcome, patient_satisfaction) against this copy before writing
-- accepted_values tests from anything other than what is confirmed here. See
-- docs/adding-an-industry.md Step 1.
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with source as (

    select * from {{ source('healthcare_raw', 'cds_records') }}

),

renamed as (

    select

        -- ---- keys ---------------------------------------------------------
        cast(record_id as varchar) as record_id,
        cast(patient_id as varchar) as patient_id,

        -- ---- clinical dimensions (structured, not free text) --------------------------
        cast(diagnosis as varchar) as diagnosis,
        cast(medical_conditions as varchar) as medical_conditions,
        cast(medication_adherence as varchar) as medication_adherence,
        cast(treatment_outcome as varchar) as treatment_outcome,
        cast(patient_satisfaction as varchar) as patient_satisfaction,

        -- ---- outcome and risk measures -----------------------------------------------
        cast(readmission_risk as number(9, 4)) as readmission_risk,
        cast(patient_outcome_score as number(9, 4)) as patient_outcome_score,
        cast(medical_error_rate as number(9, 4)) as medical_error_rate,
        cast(length_of_stay as number(38, 0)) as length_of_stay,

        -- ---- cost measures --------------------------------------------------------
        cast(cost_of_care as number(18, 2)) as cost_of_care,
        cast(medication_cost as number(18, 2)) as medication_cost,
        cast(total_cost_savings as number(18, 2)) as total_cost_savings,

        -- ---- trial linkage (informational only, not an enforced foreign key) ------------
        cast(clinical_trial_id as varchar) as clinical_trial_id,
        cast(trial_name as varchar) as trial_name,
        cast(trial_status as varchar) as trial_status,

        -- ---- publication metadata --------------------------------------------------
        cast(medical_publication_id as varchar) as medical_publication_id,
        cast(publication_date as date) as publication_date,

        -- ---- load audit -----------------------------------------------------------
        cast(_fivetran_synced as timestamp_tz) as fivetran_synced_at

    from source

)

select * from renamed
