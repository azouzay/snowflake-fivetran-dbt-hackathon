-- ---------------------------------------------------------------------------
-- sv_hcp_clinical_decisions
--
-- A Snowflake Semantic View over the healthcare clinical decisions mart.
-- Single logical table; see sv_hcp_clinical_trials.sql for why this track
-- has two Semantic Views instead of one joined view.
--
-- Governance note. No free-text PHI reaches this mart; see the governance
-- note in stg_cds_records.sql. This is the moment in this track equivalent to
-- the financial services track's "ask the agent for a social security number
-- and watch it fail" beat: ask this agent for a patient's medical history or
-- genetic data, and it cannot answer, because the column does not exist.
-- ---------------------------------------------------------------------------

{{ config(materialized='semantic_view') }}

TABLES (

    CLINICAL_DECISIONS AS {{ ref('hcp_clinical_decisions') }}
        PRIMARY KEY (record_id)
        WITH SYNONYMS = ('decisions', 'clinical decisions', 'patient outcomes', 'treatment outcomes')
        COMMENT = 'One row per patient clinical-decision record. Data flows from Google Cloud PostgreSQL through Fivetran to Snowflake. Use to identify high-risk patients, review treatment effectiveness, and analyze cost of care. Contains no PHI free text.'

)

FACTS (

    CLINICAL_DECISIONS.READMISSION_RISK AS CLINICAL_DECISIONS.readmission_risk
        COMMENT = 'Predicted probability of readmission, 0 to 1. Above 0.6 is High risk.',

    CLINICAL_DECISIONS.PATIENT_OUTCOME_SCORE AS CLINICAL_DECISIONS.patient_outcome_score
        COMMENT = 'Treatment outcome quality, 0 to 1. Above 0.7 is Good, below 0.4 is Poor.',

    CLINICAL_DECISIONS.MEDICAL_ERROR_RATE AS CLINICAL_DECISIONS.medical_error_rate
        COMMENT = 'Rate of medical errors, 0 to 1.',

    CLINICAL_DECISIONS.LENGTH_OF_STAY AS CLINICAL_DECISIONS.length_of_stay
        COMMENT = 'Number of days the patient stayed in care.',

    CLINICAL_DECISIONS.COST_OF_CARE AS CLINICAL_DECISIONS.cost_of_care
        COMMENT = 'Total cost of patient care in dollars.',

    CLINICAL_DECISIONS.MEDICATION_COST AS CLINICAL_DECISIONS.medication_cost
        COMMENT = 'Cost of medications prescribed.',

    CLINICAL_DECISIONS.TOTAL_TREATMENT_COST AS CLINICAL_DECISIONS.total_treatment_cost
        COMMENT = 'Cost of care plus medication cost.',

    CLINICAL_DECISIONS.TOTAL_COST_SAVINGS AS CLINICAL_DECISIONS.total_cost_savings
        COMMENT = 'Estimated cost savings from clinical decision support interventions.',

    CLINICAL_DECISIONS.COST_EFFICIENCY AS CLINICAL_DECISIONS.cost_efficiency
        COMMENT = 'Ratio of cost savings to total treatment cost. Higher is more cost-effective.'

)

DIMENSIONS (

    CLINICAL_DECISIONS.AS_OF_DATE AS CLINICAL_DECISIONS.as_of_date
        WITH SYNONYMS = ('as of date', 'snapshot date')
        COMMENT = 'Snapshot date every row carries. The source has no per-decision date.',

    CLINICAL_DECISIONS.DIAGNOSIS AS CLINICAL_DECISIONS.diagnosis
        WITH SYNONYMS = ('diagnosis', 'condition', 'what they were treated for')
        COMMENT = 'Primary diagnosis category.',

    CLINICAL_DECISIONS.MEDICATION_ADHERENCE AS CLINICAL_DECISIONS.medication_adherence
        WITH SYNONYMS = ('adherence', 'medication compliance')
        COMMENT = 'Patient medication compliance category.',

    CLINICAL_DECISIONS.TREATMENT_OUTCOME AS CLINICAL_DECISIONS.treatment_outcome
        WITH SYNONYMS = ('outcome', 'treatment result', 'did it work')
        COMMENT = 'Result of treatment.',

    CLINICAL_DECISIONS.PATIENT_SATISFACTION AS CLINICAL_DECISIONS.patient_satisfaction
        WITH SYNONYMS = ('satisfaction', 'patient satisfaction')
        COMMENT = 'Patient satisfaction category.',

    CLINICAL_DECISIONS.READMISSION_RISK_LEVEL AS CLINICAL_DECISIONS.readmission_risk_level
        WITH SYNONYMS = ('risk level', 'readmission risk level', 'how risky')
        COMMENT = 'Low, Medium or High, banded from readmission_risk.',

    CLINICAL_DECISIONS.OUTCOME_QUALITY AS CLINICAL_DECISIONS.outcome_quality
        WITH SYNONYMS = ('outcome quality', 'how good was the outcome')
        COMMENT = 'Good, Fair or Poor, banded from patient_outcome_score.',

    CLINICAL_DECISIONS.STAY_CATEGORY AS CLINICAL_DECISIONS.stay_category
        WITH SYNONYMS = ('stay category', 'length of stay band')
        COMMENT = 'Short, Medium or Long, banded from length_of_stay.',

    CLINICAL_DECISIONS.NEEDS_REVIEW AS CLINICAL_DECISIONS.needs_review
        WITH SYNONYMS = ('needs review', 'flag for review')
        COMMENT = 'True when readmission risk is over 0.5 and either adherence is poor or the error rate is elevated.'

)

METRICS (

    CLINICAL_DECISIONS.AVERAGE_READMISSION_RISK AS AVG(CLINICAL_DECISIONS.READMISSION_RISK)
        WITH SYNONYMS = ('average readmission risk', 'readmission risk')
        COMMENT = 'Average predicted readmission risk, 0 to 1.',

    CLINICAL_DECISIONS.AVERAGE_OUTCOME_SCORE AS AVG(CLINICAL_DECISIONS.PATIENT_OUTCOME_SCORE)
        WITH SYNONYMS = ('average outcome score', 'outcome quality')
        COMMENT = 'Average treatment outcome quality, 0 to 1.',

    CLINICAL_DECISIONS.AVERAGE_MEDICAL_ERROR_RATE AS AVG(CLINICAL_DECISIONS.MEDICAL_ERROR_RATE)
        WITH SYNONYMS = ('error rate', 'medical error rate')
        COMMENT = 'Average rate of medical errors, 0 to 1.',

    CLINICAL_DECISIONS.TOTAL_TREATMENT_COST AS SUM(CLINICAL_DECISIONS.TOTAL_TREATMENT_COST)
        WITH SYNONYMS = ('total cost', 'total treatment cost', 'how much did it cost')
        COMMENT = 'Total treatment cost in dollars.',

    CLINICAL_DECISIONS.AVERAGE_COST_EFFICIENCY AS AVG(CLINICAL_DECISIONS.COST_EFFICIENCY)
        WITH SYNONYMS = ('cost efficiency', 'average cost efficiency')
        COMMENT = 'Average ratio of cost savings to total treatment cost.',

    CLINICAL_DECISIONS.NEEDS_REVIEW_COUNT AS SUM(CASE WHEN CLINICAL_DECISIONS.NEEDS_REVIEW THEN 1 ELSE 0 END)
        WITH SYNONYMS = ('cases needing review', 'how many need review')
        COMMENT = 'Number of cases flagged for clinical review.',

    CLINICAL_DECISIONS.DECISION_COUNT AS COUNT(CLINICAL_DECISIONS.RECORD_ID)
        WITH SYNONYMS = ('number of cases', 'how many patients')
        COMMENT = 'Number of clinical-decision records.',

    CLINICAL_DECISIONS.NEEDS_REVIEW_RATE AS SUM(CASE WHEN CLINICAL_DECISIONS.NEEDS_REVIEW THEN 1 ELSE 0 END) / NULLIF(COUNT(CLINICAL_DECISIONS.RECORD_ID), 0)
        WITH SYNONYMS = ('review rate', 'share needing review')
        COMMENT = 'Share of cases flagged for clinical review, 0 to 1.'

)

COMMENT = 'Healthcare clinical decisions, for the healthcare, pharma and life sciences track of the Fivetran, Snowflake and dbt hands-on lab. Contains no PHI free text by design.'
