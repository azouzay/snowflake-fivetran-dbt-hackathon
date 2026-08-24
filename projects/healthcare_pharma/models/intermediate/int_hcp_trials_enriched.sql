-- ---------------------------------------------------------------------------
-- int_hcp_trials_enriched
--
-- Pharma clinical trials, with the derived risk view of the pipeline: is a
-- trial stalling (low enrollment, high dropout) or already in trouble
-- (terminated, suspended, withdrawn).
--
-- trial_risk_score and the status lists it depends on are carried over from a
-- working model against the same source schema (see BUILD-NOTES.md), NOT yet
-- re-verified against this track's own Fivetran-landed copy. Confirm the real
-- trial_status value list (docs/adding-an-industry.md Step 1) before treating
-- the score as calibrated.
--
-- Grain: one row per record_id (one patient enrollment in one trial).
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with trials as (

    select * from {{ ref('stg_phr_records') }}

),

enriched as (

    select

        record_id,
        trial_id,
        protocol_id,
        patient_id,
        site_id,
        trial_name,
        sponsor_name,
        disease_area,
        site_name,
        trial_status,
        regulatory_approval_status,
        patient_age,
        patient_gender,
        enrollment_date,
        protocol_amendment_date,
        enrollment_rate,
        dropout_rate,

        -- ---- age banding ----------------------------------------------------------
        case
            when patient_age between 18 and 30 then '18-30'
            when patient_age between 31 and 45 then '31-45'
            when patient_age between 46 and 60 then '46-60'
            when patient_age between 61 and 80 then '61-80'
            else 'Other'
        end as age_group,

        -- ---- timing -------------------------------------------------------------
        datediff('day', enrollment_date, current_date()) as days_since_enrollment,
        datediff('day', enrollment_date, protocol_amendment_date) as days_to_amendment,

        -- ---- trial risk score, 0-100, higher = more risk -------------------------------
        -- Weighted from dropout rate (50%), inverse enrollment rate (30%), and a
        -- status penalty (20%) for trials already in a troubled state.
        round(
            (dropout_rate * 0.5)
            + ((100 - enrollment_rate) * 0.3)
            + (case
                when trial_status in ('Terminated', 'Suspended', 'Withdrawn') then 20
                when trial_status in ('Inactive', 'Closed') then 10
                else 0
            end),
            2
        ) as trial_risk_score,

        -- ---- at-risk flag: high dropout and low enrollment on a still-active trial -----------
        case
            when dropout_rate > 40
                and enrollment_rate < 30
                and trial_status in ('Recruiting', 'Enrolling', 'Active', 'Pre-Enrollment')
            then true
            else false
        end as is_at_risk

    from trials

)

select * from enriched
