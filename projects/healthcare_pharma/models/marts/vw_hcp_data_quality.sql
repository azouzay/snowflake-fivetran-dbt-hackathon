-- ---------------------------------------------------------------------------
-- vw_hcp_data_quality
--
-- Data-quality scorecard, one row per subject area. No contract here on
-- purpose: this is the model the lab edits live during the dbt Studio and
-- Fusion tour, same role as vw_fs_data_quality in the financial services
-- track.
--
-- Grain: one row per data_domain.
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with trials as (

    select * from {{ ref('stg_phr_records') }}

),

decisions as (

    select * from {{ ref('stg_cds_records') }}

),

-- ---- pharma trial checks -----------------------------------------------------
trial_checks as (

    select
        'Clinical trials' as data_domain,
        count(*) as total_rows,

        -- completeness
        sum(case when disease_area is null or trim(disease_area) = '' then 1 else 0 end)
            + sum(case when trial_status is null or trim(trial_status) = '' then 1 else 0 end)
            as completeness_failures,
        2 as completeness_checks,

        -- validity: enrollment and dropout are percentages
        sum(case when enrollment_rate < 0 or enrollment_rate > 100 then 1 else 0 end)
            + sum(case when dropout_rate < 0 or dropout_rate > 100 then 1 else 0 end)
            + sum(case when patient_age < 0 or patient_age > 120 then 1 else 0 end)
            as validity_failures,
        3 as validity_checks,

        -- consistency: a protocol amendment dated before enrollment is a real
        -- possibility in this data (a protocol can be amended retroactively),
        -- but a dropout rate over 100 alongside an enrollment rate over 100
        -- would be a self-contradiction worth flagging
        sum(case when enrollment_rate > 100 and dropout_rate > 100 then 1 else 0 end)
            as consistency_failures,
        1 as consistency_checks

    from trials

),

-- ---- healthcare decision checks -----------------------------------------------
decision_checks as (

    select
        'Clinical decisions' as data_domain,
        count(*) as total_rows,

        -- completeness
        sum(case when diagnosis is null or trim(diagnosis) = '' then 1 else 0 end)
            + sum(case when medication_adherence is null or trim(medication_adherence) = '' then 1 else 0 end)
            as completeness_failures,
        2 as completeness_checks,

        -- validity: the three source measures are documented as 0-1 probabilities
        sum(case when readmission_risk < 0 or readmission_risk > 1 then 1 else 0 end)
            + sum(case when patient_outcome_score < 0 or patient_outcome_score > 1 then 1 else 0 end)
            + sum(case when medical_error_rate < 0 or medical_error_rate > 1 then 1 else 0 end)
            as validity_failures,
        3 as validity_checks,

        -- consistency: a high readmission risk with a "Good" outcome would be
        -- two signals disagreeing about the same patient
        sum(case when readmission_risk > 0.6 and patient_outcome_score > 0.7 then 1 else 0 end)
            as consistency_failures,
        1 as consistency_checks

    from decisions

),

-- ---- combine and score -----------------------------------------------------------
combined as (

    select * from trial_checks
    union all
    select * from decision_checks

),

scored as (

    select
        data_domain,
        total_rows,
        completeness_failures,
        validity_failures,
        consistency_failures,

        round(100 - (100.0 * completeness_failures / nullif(total_rows * completeness_checks, 0)), 2) as completeness_score,
        round(100 - (100.0 * validity_failures / nullif(total_rows * validity_checks, 0)), 2) as validity_score,
        round(100 - (100.0 * consistency_failures / nullif(total_rows * consistency_checks, 0)), 2) as consistency_score

    from combined

),

final as (

    select
        data_domain,
        total_rows,
        completeness_score,
        validity_score,
        consistency_score,

        round((completeness_score + validity_score + consistency_score) / 3, 2) as data_quality_score,

        case
            when (completeness_score + validity_score + consistency_score) / 3 >= 95 then 'A'
            when (completeness_score + validity_score + consistency_score) / 3 >= 90 then 'B'
            when (completeness_score + validity_score + consistency_score) / 3 >= 80 then 'C'
            else 'D'
        end as data_quality_grade,

        completeness_failures,
        validity_failures,
        consistency_failures

    from scored

)

select * from final
order by data_quality_score asc
