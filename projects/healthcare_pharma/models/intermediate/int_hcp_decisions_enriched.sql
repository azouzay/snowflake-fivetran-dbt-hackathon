-- ---------------------------------------------------------------------------
-- int_hcp_decisions_enriched
--
-- Healthcare clinical decisions, with the derived view of patient outcome and
-- cost: is this treatment working, is the patient at risk of readmission, and
-- does the case need clinical review.
--
-- Thresholds carried over from a working model against the same source
-- schema (see BUILD-NOTES.md), NOT yet re-verified against this track's own
-- Fivetran-landed copy. Confirm before treating the bands as calibrated.
--
-- Grain: one row per record_id (one patient clinical-decision record).
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with decisions as (

    select * from {{ ref('stg_cds_records') }}

),

enriched as (

    select

        -- The source has no per-decision date (publication_date exists but is
        -- sparse and describes an associated publication, not the decision
        -- itself). The dbt Semantic Layer needs a time dimension to aggregate
        -- against, and for a mart with no natural one, a snapshot date every
        -- row carries is the honest choice, same move the financial services
        -- track makes with as_of_date.
        current_date() as as_of_date,

        record_id,
        patient_id,
        diagnosis,
        medical_conditions,
        medication_adherence,
        treatment_outcome,
        patient_satisfaction,
        readmission_risk,
        patient_outcome_score,
        medical_error_rate,
        length_of_stay,
        cost_of_care,
        medication_cost,
        total_cost_savings,
        clinical_trial_id,
        trial_name,
        trial_status,
        medical_publication_id,
        publication_date,

        -- ---- cost --------------------------------------------------------------------
        round(cost_of_care + medication_cost, 2) as total_treatment_cost,
        round(total_cost_savings / nullif(cost_of_care + medication_cost, 0), 4) as cost_efficiency,

        -- ---- readmission risk band --------------------------------------------------
        case
            when readmission_risk < 0.3 then 'Low'
            when readmission_risk between 0.3 and 0.6 then 'Medium'
            when readmission_risk > 0.6 then 'High'
        end as readmission_risk_level,

        -- ---- outcome quality band --------------------------------------------------
        case
            when patient_outcome_score > 0.7 then 'Good'
            when patient_outcome_score between 0.4 and 0.7 then 'Fair'
            when patient_outcome_score < 0.4 then 'Poor'
        end as outcome_quality,

        -- ---- length of stay band ----------------------------------------------------
        case
            when length_of_stay < 30 then 'Short'
            when length_of_stay between 30 and 120 then 'Medium'
            when length_of_stay > 120 then 'Long'
        end as stay_category,

        -- ---- needs clinical review ---------------------------------------------------
        case
            when readmission_risk > 0.5
                and (medication_adherence = 'Non-Adherent' or medical_error_rate > 0.08)
            then true
            else false
        end as needs_review

    from decisions

)

select * from enriched
