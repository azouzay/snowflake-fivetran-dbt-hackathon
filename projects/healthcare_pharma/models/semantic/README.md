# dbt Semantic Layer definitions for the healthcare, pharma & life sciences track

**The definitions are not in this folder. They are in
[`../marts/_healthcare_pharma__marts.yml`](../marts/_healthcare_pharma__marts.yml).**

That is not an accident, and it is worth understanding.

## Why they moved

The dbt Semantic Layer used to be declared with top-level `semantic_models:`
and `metrics:` keys in their own file, which is what this folder was for. The
latest spec, which the Fusion engine requires, embeds the semantic annotations
directly in the model they describe:

| | Legacy spec | Latest spec (what this project uses) |
|---|---|---|
| Semantic model | top-level `semantic_models:` with `model: ref(...)` | `semantic_model: {enabled: true}` under the model |
| Entities and dimensions | separate `entities:` and `dimensions:` lists | `entity:` and `dimension:` on the column itself |
| Measures | `measures:` list, then a metric wrapping each one | gone; a simple metric with `agg:` and `expr:` |
| Metric parameters | nested under `type_params:` | promoted to top-level keys |

A dbt model can only be configured in one YAML file, so once the semantic
annotations attach to columns, they have to live beside the contract.

## What to read

- **[`../marts/_healthcare_pharma__marts.yml`](../marts/_healthcare_pharma__marts.yml)** for the metrics, entities and
  dimensions. Look for the `semantic_model:` and `metrics:` blocks under each
  mart.
- **[`../marts/`](../marts/)** for `sv_hcp_clinical_trials.sql` and
  `sv_hcp_clinical_decisions.sql`, the two Snowflake Semantic Views, which are
  the other way this track defines meaning.

## What still belongs in this folder

Top-level `metrics:` are still valid in a standalone file, and that is the
right home for a metric that spans more than one model. Pharma and healthcare
share no key here, so there is not one yet. If you add one, put it here as
`healthcare_pharma.yml`.
