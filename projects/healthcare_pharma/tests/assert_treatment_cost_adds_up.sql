-- Singular test: total_treatment_cost must always equal cost_of_care plus
-- medication_cost. It is a derived column, not an independent source fact,
-- and the two should never be allowed to drift apart under a future refactor.

select
    record_id,
    cost_of_care,
    medication_cost,
    total_treatment_cost
from {{ ref('hcp_clinical_decisions') }}
where round(cost_of_care + medication_cost, 2) <> total_treatment_cost
