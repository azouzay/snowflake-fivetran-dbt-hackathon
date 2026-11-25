-- ---------------------------------------------------------------------------
-- energy_maintenance_logs
--
-- Business-facing maintenance fact. One row per maintenance event, after the
-- two source feeds have been combined and de-duplicated.
--
-- Contract enforced (see _energy__marts.yml), so every column is cast
-- explicitly.
--
-- Grain: one row per maintenance_log_id.
-- ---------------------------------------------------------------------------

{{ config(materialized='table') }}

with logs as (

    -- Project only the columns this mart publishes or uses in derivations.
    select
        maintenance_log_id,
        equipment_id,
        technician_id,
        customer_id,
        erp_order_id,
        log_date,
        maintenance_type,
        maintenance_status,
        source_system,
        failure_rate,
        maintenance_cost,
        downtime_hours,
        summarization_hours_saved,
        is_reported_by_both_feeds,
        summarized_log
    from {{ ref('int_energy_maintenance_logs_unioned') }}

)

select

    -- ---- keys ---------------------------------------------------------------
    cast(maintenance_log_id as varchar) as maintenance_log_id,
    cast(equipment_id as varchar) as equipment_id,
    cast(technician_id as varchar) as technician_id,
    cast(customer_id as varchar) as customer_id,
    cast(erp_order_id as varchar) as erp_order_id,

    -- ---- time ---------------------------------------------------------------
    cast(log_date as date) as log_date,

    -- ---- dimensions ---------------------------------------------------------
    cast(maintenance_type as varchar) as maintenance_type,
    cast(maintenance_status as varchar) as maintenance_status,
    cast(
        case
            when downtime_hours >= 8 then 'Major'
            when downtime_hours >= 4 then 'Moderate'
            else 'Minor'
        end
        as varchar
    ) as downtime_band,
    cast(
        case
            when maintenance_type = 'Corrective Maintenance' then 'Unplanned'
            else 'Planned'
        end
        as varchar
    ) as work_class,
    cast(source_system as varchar) as source_system,

    -- ---- measures -----------------------------------------------------------
    cast(failure_rate as number(9, 4)) as failure_rate,
    cast(maintenance_cost as number(18, 2)) as maintenance_cost,
    cast(downtime_hours as number(38, 0)) as downtime_hours,
    cast(
        round(maintenance_cost / nullif(downtime_hours, 0), 2)
        as number(18, 2)
    ) as cost_per_downtime_hour,
    cast(summarization_hours_saved as number(38, 0)) as summarization_hours_saved,

    -- ---- flags --------------------------------------------------------------
    cast(maintenance_status = 'Completed' as boolean) as is_completed,
    cast(maintenance_status in ('Delayed', 'Cancelled') as boolean) as is_at_risk,
    cast(is_reported_by_both_feeds as boolean) as is_reported_by_both_feeds,

    -- ---- text ---------------------------------------------------------------
    cast(summarized_log as varchar) as summarized_log

from logs
