-- ---------------------------------------------------------------------------
-- hcp_clinical_trials
--
-- The pharma headline mart: one row per patient enrollment, with risk score
-- and at-risk flag attached. This is where "which trials are stalling" gets
-- answered.
--
-- Contract enforced (see _healthcare_pharma__marts.yml).
--
-- Grain: one row per record_id.
-- ---------------------------------------------------------------------------

{{ config(materialized='table') }}

with enriched as (

    select * from {{ ref('int_hcp_trials_enriched') }}

)

select

    -- ---- keys ---------------------------------------------------------------
    cast(record_id as varchar) as record_id,
    cast(trial_id as varchar) as trial_id,
    cast(protocol_id as varchar) as protocol_id,
    cast(patient_id as varchar) as patient_id,
    cast(site_id as varchar) as site_id,

    -- ---- trial dimensions -----------------------------------------------------
    cast(trial_name as varchar) as trial_name,
    cast(sponsor_name as varchar) as sponsor_name,
    cast(disease_area as varchar) as disease_area,
    cast(site_name as varchar) as site_name,
    cast(trial_status as varchar) as trial_status,
    cast(regulatory_approval_status as varchar) as regulatory_approval_status,

    -- ---- patient dimensions ------------------------------------------------------
    cast(patient_age as number(38, 0)) as patient_age,
    cast(patient_gender as varchar) as patient_gender,
    cast(age_group as varchar) as age_group,

    -- ---- dates -------------------------------------------------------------------
    cast(enrollment_date as date) as enrollment_date,
    cast(protocol_amendment_date as date) as protocol_amendment_date,
    cast(days_since_enrollment as number(38, 0)) as days_since_enrollment,
    cast(days_to_amendment as number(38, 0)) as days_to_amendment,

    -- ---- trial performance and risk measures -------------------------------------------
    cast(enrollment_rate as number(9, 2)) as enrollment_rate,
    cast(dropout_rate as number(9, 2)) as dropout_rate,
    cast(trial_risk_score as number(9, 2)) as trial_risk_score,

    -- ---- flags -----------------------------------------------------------------
    cast(is_at_risk as boolean) as is_at_risk

from enriched
