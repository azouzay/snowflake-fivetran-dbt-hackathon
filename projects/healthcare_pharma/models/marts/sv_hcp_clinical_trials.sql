-- ---------------------------------------------------------------------------
-- sv_hcp_clinical_trials
--
-- A Snowflake Semantic View over the pharma clinical trials mart. Single
-- logical table; pharma and healthcare share no key, so they get one
-- Semantic View each rather than being forced into a join that doesn't exist.
--
-- Governance note. Every column exposed here comes from a mart with an
-- enforced contract, and no free-text PHI reaches it. Compare with the
-- `semantic_model:` and `metrics:` blocks in _healthcare_pharma__marts.yml,
-- which express the same ideas as dbt Semantic Layer (MetricFlow) specs.
-- ---------------------------------------------------------------------------

{{ config(materialized='semantic_view') }}

TABLES (

    CLINICAL_TRIALS AS {{ ref('hcp_clinical_trials') }}
        PRIMARY KEY (record_id)
        WITH SYNONYMS = ('trials', 'clinical trials', 'pipeline', 'trial pipeline')
        COMMENT = 'One row per patient enrollment in a clinical trial. Data flows from Google Cloud PostgreSQL through Fivetran to Snowflake. Use to analyze trial performance, patient demographics, sponsor effectiveness and clinical risk.'

)

FACTS (

    CLINICAL_TRIALS.PATIENT_AGE AS CLINICAL_TRIALS.patient_age
        COMMENT = 'Age of the patient at enrollment.',

    CLINICAL_TRIALS.DAYS_SINCE_ENROLLMENT AS CLINICAL_TRIALS.days_since_enrollment
        COMMENT = 'Number of days from patient enrollment to today.',

    CLINICAL_TRIALS.DAYS_TO_AMENDMENT AS CLINICAL_TRIALS.days_to_amendment
        COMMENT = 'Days between enrollment and the most recent protocol amendment.',

    CLINICAL_TRIALS.ENROLLMENT_RATE AS CLINICAL_TRIALS.enrollment_rate
        COMMENT = 'Percentage of target patients successfully enrolled. Lower values suggest recruitment challenges.',

    CLINICAL_TRIALS.DROPOUT_RATE AS CLINICAL_TRIALS.dropout_rate
        COMMENT = 'Percentage of enrolled patients who discontinued before completion. Elevated values may indicate safety concerns or protocol burden.',

    CLINICAL_TRIALS.TRIAL_RISK_SCORE AS CLINICAL_TRIALS.trial_risk_score
        COMMENT = 'Composite risk score, 50% dropout rate, 30% inverse enrollment rate, 20% trial-status penalty. Higher means more at risk.'

)

DIMENSIONS (

    CLINICAL_TRIALS.DISEASE_AREA AS CLINICAL_TRIALS.disease_area
        WITH SYNONYMS = ('disease area', 'therapeutic area', 'specialty')
        COMMENT = 'Medical specialty the trial addresses.',

    CLINICAL_TRIALS.SPONSOR_NAME AS CLINICAL_TRIALS.sponsor_name
        WITH SYNONYMS = ('sponsor', 'who is running it')
        COMMENT = 'Organization sponsoring the trial.',

    CLINICAL_TRIALS.TRIAL_STATUS AS CLINICAL_TRIALS.trial_status
        WITH SYNONYMS = ('status', 'trial status', 'is it still running')
        COMMENT = 'Current operational status of the trial.',

    CLINICAL_TRIALS.REGULATORY_APPROVAL_STATUS AS CLINICAL_TRIALS.regulatory_approval_status
        WITH SYNONYMS = ('regulatory status', 'approval status')
        COMMENT = 'Regulatory review status.',

    CLINICAL_TRIALS.AGE_GROUP AS CLINICAL_TRIALS.age_group
        WITH SYNONYMS = ('age group', 'age band')
        COMMENT = 'Patient age banded into 18-30, 31-45, 46-60 or 61-80.',

    CLINICAL_TRIALS.PATIENT_GENDER AS CLINICAL_TRIALS.patient_gender
        WITH SYNONYMS = ('gender', 'sex')
        COMMENT = 'Patient gender.',

    CLINICAL_TRIALS.IS_AT_RISK AS CLINICAL_TRIALS.is_at_risk
        WITH SYNONYMS = ('at risk', 'is this trial at risk')
        COMMENT = 'True when dropout is over 40%, enrollment is under 30%, and the trial is still notionally active.'

)

METRICS (

    CLINICAL_TRIALS.AVERAGE_TRIAL_RISK_SCORE AS AVG(CLINICAL_TRIALS.TRIAL_RISK_SCORE)
        WITH SYNONYMS = ('average risk score', 'trial risk', 'how risky are our trials')
        COMMENT = 'Average trial risk score across enrollments.',

    CLINICAL_TRIALS.AVERAGE_ENROLLMENT_RATE AS AVG(CLINICAL_TRIALS.ENROLLMENT_RATE)
        WITH SYNONYMS = ('enrollment rate', 'average enrollment rate', 'recruitment')
        COMMENT = 'Average enrollment rate across trials.',

    CLINICAL_TRIALS.AVERAGE_DROPOUT_RATE AS AVG(CLINICAL_TRIALS.DROPOUT_RATE)
        WITH SYNONYMS = ('dropout rate', 'average dropout rate', 'attrition')
        COMMENT = 'Average dropout rate across trials.',

    CLINICAL_TRIALS.AT_RISK_COUNT AS SUM(CASE WHEN CLINICAL_TRIALS.IS_AT_RISK THEN 1 ELSE 0 END)
        WITH SYNONYMS = ('at risk trials', 'how many trials are at risk')
        COMMENT = 'Number of enrollments flagged as at risk.',

    CLINICAL_TRIALS.ENROLLMENT_COUNT AS COUNT(CLINICAL_TRIALS.RECORD_ID)
        WITH SYNONYMS = ('number of enrollments', 'how many patients')
        COMMENT = 'Number of patient enrollments.',

    CLINICAL_TRIALS.AT_RISK_RATE AS SUM(CASE WHEN CLINICAL_TRIALS.IS_AT_RISK THEN 1 ELSE 0 END) / NULLIF(COUNT(CLINICAL_TRIALS.RECORD_ID), 0)
        WITH SYNONYMS = ('at risk rate', 'share of trials at risk')
        COMMENT = 'Share of enrollments flagged as at risk, 0 to 1.'

)

COMMENT = 'Pharma clinical trial risk, for the healthcare, pharma and life sciences track of the Fivetran, Snowflake and dbt hands-on lab. Contains no PHI free text.'
