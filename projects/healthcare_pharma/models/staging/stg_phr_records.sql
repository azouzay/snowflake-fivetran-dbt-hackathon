-- ---------------------------------------------------------------------------
-- stg_phr_records
--
-- One row per patient enrollment in a clinical trial.
--
-- Adapted from a working model against the same source schema (see
-- BUILD-NOTES.md); casts and column list carried over, but exact row counts,
-- every value of every categorical column, and ranges have NOT yet been
-- re-verified against this track's own Fivetran-landed copy. Do that before
-- the event, per docs/adding-an-industry.md Step 1.
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with source as (

    select * from {{ source('pharma_raw', 'phr_records') }}

),

renamed as (

    select

        -- ---- keys ---------------------------------------------------------
        cast(record_id as varchar) as record_id,
        cast(trial_id as varchar) as trial_id,
        cast(protocol_id as varchar) as protocol_id,
        cast(patient_id as varchar) as patient_id,
        cast(site_id as varchar) as site_id,

        -- ---- trial dimensions -----------------------------------------------
        cast(trial_name as varchar) as trial_name,
        cast(sponsor_name as varchar) as sponsor_name,
        cast(disease_area as varchar) as disease_area,
        cast(site_name as varchar) as site_name,
        cast(trial_status as varchar) as trial_status,
        cast(regulatory_approval_status as varchar) as regulatory_approval_status,

        -- ---- patient dimensions ----------------------------------------------
        cast(patient_age as number(38, 0)) as patient_age,
        cast(patient_gender as varchar) as patient_gender,

        -- ---- dates -------------------------------------------------------------
        cast(enrollment_date as date) as enrollment_date,
        cast(protocol_amendment_date as date) as protocol_amendment_date,

        -- ---- trial performance measures --------------------------------------------
        cast(enrollment_rate as number(9, 2)) as enrollment_rate,
        cast(dropout_rate as number(9, 2)) as dropout_rate,

        -- ---- load audit -----------------------------------------------------------
        cast(_fivetran_synced as timestamp_tz) as fivetran_synced_at

    from source

)

select * from renamed
