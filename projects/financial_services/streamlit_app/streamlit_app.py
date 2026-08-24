# ---------------------------------------------------------------------------
# Financial services: credit risk dashboard
#
# Streamlit in Snowflake, reading directly from the governed marts this
# track's dbt project produces (fs_risk_relationship_summary and
# fs_monthly_risk_assessment). No personal data reaches either mart, so this
# app inherits the same governance guarantee the Cortex Agent gets: nothing
# here can show a social security number, because the column does not exist
# upstream of it either.
#
# Declared as a dbt exposure in models/marts/_financial_services__exposures.yml,
# so it appears in the dbt DAG and dbt Catalog next to sv_fs_credit_risk.
#
# Pre-built starter, plain SQL throughout on purpose so it is easy to read
# and easy to extend without learning a DataFrame API mid-hackathon.
#
# In-session task: add one more tile or filter, marked with the TODO at the
# bottom of this file.
# ---------------------------------------------------------------------------

import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Credit risk dashboard", layout="wide")
st.title("Financial services: credit risk dashboard")
st.caption(
    "Reads fs_risk_relationship_summary and fs_monthly_risk_assessment, "
    "the same governed marts the HOL_FS_ANALYST Cortex Agent reads."
)

session = get_active_session()

# ---- headline tiles ---------------------------------------------------------
totals = session.sql(
    """
    select
        sum(total_exposure) as total_exposure,
        sum(risk_weighted_exposure) as total_risk_weighted_exposure,
        avg(base_risk_score) as average_base_risk_score
    from fs_risk_relationship_summary
    """
).to_pandas()

col1, col2, col3 = st.columns(3)
col1.metric("Total exposure (USD)", f"{totals.iloc[0]['TOTAL_EXPOSURE']:,.0f}")
col2.metric(
    "Total risk-weighted exposure (USD)",
    f"{totals.iloc[0]['TOTAL_RISK_WEIGHTED_EXPOSURE']:,.0f}",
)
col3.metric("Average base risk score", f"{totals.iloc[0]['AVERAGE_BASE_RISK_SCORE']:.2f}")

# ---- exposure by customer segment -------------------------------------------
st.subheader("Exposure by customer segment")
by_segment = session.sql(
    """
    select customer_segment, sum(total_exposure) as total_exposure
    from fs_risk_relationship_summary
    group by customer_segment
    order by total_exposure desc
    """
).to_pandas()
st.bar_chart(by_segment.set_index("CUSTOMER_SEGMENT"))

# ---- monthly denial rate -----------------------------------------------------
st.subheader("Monthly denial rate")
denials = session.sql(
    """
    select
        assessment_year,
        assessment_month,
        sum(case when approval_recommendation = 'Deny' then 1 else 0 end)
            / count(*) as denial_rate
    from fs_monthly_risk_assessment
    group by assessment_year, assessment_month
    order by assessment_year, assessment_month
    """
).to_pandas()
denials["MONTH"] = denials["ASSESSMENT_YEAR"].astype(str) + "-" + denials["ASSESSMENT_MONTH"].astype(str).str.zfill(2)
st.line_chart(denials.set_index("MONTH")["DENIAL_RATE"])
st.caption(
    "Same definition as the dbt Semantic Layer's `denial_rate` metric and "
    "sv_fs_credit_risk.DENIAL_RATE in the Snowflake Semantic View. Three "
    "surfaces, one number."
)

# ---------------------------------------------------------------------------
# TODO (hackathon task): add one more KPI tile or filter here.
#
# Ideas that stay within the existing contract, no new mart needed:
#   - A tile for prior_bankruptcy_rate or unassessed_collateral_rate
#   - A st.selectbox filter on institution_type or region, applied to the
#     tiles above (add a `where institution_type = :selected` clause)
#   - A tile showing the most recent month's anomaly_rate from
#     fs_monthly_risk_assessment
# ---------------------------------------------------------------------------
