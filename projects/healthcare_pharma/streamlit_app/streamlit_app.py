# ---------------------------------------------------------------------------
# Healthcare, pharma & life sciences: trial and outcomes dashboard
#
# Streamlit in Snowflake, reading directly from the governed marts this
# track's dbt project produces (hcp_clinical_trials and
# hcp_clinical_decisions). No PHI free text reaches either mart; see the
# governance note in stg_cds_records.sql. This app inherits that guarantee:
# nothing here can show a patient's medical history, because the column
# does not exist upstream of it either.
#
# Declared as a dbt exposure in
# models/marts/_healthcare_pharma__exposures.yml, so it appears in the dbt
# DAG and dbt Catalog next to sv_hcp_clinical_trials and
# sv_hcp_clinical_decisions.
#
# Pre-built starter, plain SQL throughout. In-session task: add one more
# tile or filter, marked with the TODO at the bottom of this file.
# ---------------------------------------------------------------------------

import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Trial and outcomes dashboard", layout="wide")
st.title("Healthcare, pharma & life sciences: trial and outcomes dashboard")
st.caption(
    "Reads hcp_clinical_trials and hcp_clinical_decisions, the same "
    "governed marts the HOL_HCP_ANALYST Cortex Agent reads."
)

session = get_active_session()

tab_trials, tab_decisions = st.tabs(["Pharma: clinical trials", "Healthcare: clinical decisions"])

with tab_trials:
    totals = session.sql(
        """
        select
            count(*) as enrollment_count,
            avg(trial_risk_score) as average_trial_risk_score,
            sum(case when is_at_risk then 1 else 0 end) as at_risk_count
        from hcp_clinical_trials
        """
    ).to_pandas()

    col1, col2, col3 = st.columns(3)
    col1.metric("Enrollments", f"{int(totals.iloc[0]['ENROLLMENT_COUNT']):,}")
    col2.metric("Average trial risk score", f"{totals.iloc[0]['AVERAGE_TRIAL_RISK_SCORE']:.1f}")
    col3.metric("At-risk enrollments", f"{int(totals.iloc[0]['AT_RISK_COUNT']):,}")

    st.subheader("Average risk score by disease area")
    by_disease = session.sql(
        """
        select disease_area, avg(trial_risk_score) as average_trial_risk_score
        from hcp_clinical_trials
        group by disease_area
        order by average_trial_risk_score desc
        """
    ).to_pandas()
    st.bar_chart(by_disease.set_index("DISEASE_AREA"))

with tab_decisions:
    totals = session.sql(
        """
        select
            count(*) as decision_count,
            avg(readmission_risk) as average_readmission_risk,
            sum(case when needs_review then 1 else 0 end) as needs_review_count
        from hcp_clinical_decisions
        """
    ).to_pandas()

    col1, col2, col3 = st.columns(3)
    col1.metric("Decisions", f"{int(totals.iloc[0]['DECISION_COUNT']):,}")
    col2.metric("Average readmission risk", f"{totals.iloc[0]['AVERAGE_READMISSION_RISK']:.2f}")
    col3.metric("Cases needing review", f"{int(totals.iloc[0]['NEEDS_REVIEW_COUNT']):,}")

    st.subheader("Readmission risk level by diagnosis")
    by_diagnosis = session.sql(
        """
        select diagnosis, readmission_risk_level, count(*) as decision_count
        from hcp_clinical_decisions
        group by diagnosis, readmission_risk_level
        order by diagnosis
        """
    ).to_pandas()
    st.dataframe(by_diagnosis, use_container_width=True)

# ---------------------------------------------------------------------------
# TODO (hackathon task): add one more KPI tile or filter here.
#
# Ideas that stay within the existing contract, no new mart needed:
#   - A tile for average_cost_efficiency or total treatment cost, from
#     hcp_clinical_decisions
#   - A st.selectbox filter on trial_status, applied to the pharma tiles
#   - A tile for the dropout rate distribution across sponsors
# ---------------------------------------------------------------------------
