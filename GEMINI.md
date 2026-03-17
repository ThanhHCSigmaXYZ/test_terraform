# GEMINI.md
# This file is automatically read by Gemini CLI on every session.
# Contains project constraints and workflow for Dataform code generation.
# DO NOT modify without team lead approval.

---

## Project Context
- GCP Project: ats-theme-dmo-b2bdatacolab
- Output Dataset: dev_dataform_dataset
- Source Dataset: aiready
- Location: asia-northeast1
- Dataform Core Version: 3.0.7

---

## Folder Structure
Tables are organized into 3 layers based on their prefix:

| Table prefix | Layer | Output folder |
|---|---|---|
| `raw_` | Raw layer | `dataform/definitions/raw/` |
| `tmp_` | Processed layer | `dataform/definitions/processed/` |
| `fct_`, `dim_` | Access layer | `dataform/definitions/access/` |

Always create the folder if it does not exist before writing files.

---

## Workflow — Single Table
Only trigger when developer uses single-table trigger phrases.
Follow these steps automatically without asking for confirmation:

1. Read `docs/requirements.md` to find the requested table
2. Read `templates/sqlx_template.sqlx` as format reference
3. Determine the correct output folder based on table prefix (see Folder Structure)
4. Generate main SQLX → write to correct folder
5. Generate test SQLX following layer-specific test rules → write to same folder
6. Report files created

### Single-table trigger phrases
- "create table [name]"
- "generate dataform for [name]"
- "make [name] table"
- "generate [name]"

---

## Workflow — All Tables
Only trigger when developer uses bulk trigger phrases.
Follow these steps automatically without asking for confirmation:

1. Read `docs/requirements.md` to get the full list of all tables
2. Read `templates/sqlx_template.sqlx` as format reference
3. Create folder structure:
   - `dataform/definitions/raw/`
   - `dataform/definitions/processed/`
   - `dataform/definitions/access/`
4. For each table in `docs/requirements.md`:
   - Determine correct folder based on table prefix
   - Generate main SQLX → write to correct folder
   - Generate test SQLX following layer-specific test rules → write to same folder
5. Report summary of all files created grouped by layer

### Bulk trigger phrases
- "generate dataform files based on tables"
- "全テーブル作成"
- "create all tables"

---

## File Naming Convention
| File | Path |
|---|---|
| Requirements & Spec | `docs/requirements.md` |
| SQLX format reference | `templates/sqlx_template.sqlx` |
| Raw layer SQLX | `dataform/definitions/raw/[table_name].sqlx` |
| Raw layer test | `dataform/definitions/raw/[table_name]_test.sqlx` |
| Processed layer SQLX | `dataform/definitions/processed/[table_name].sqlx` |
| Processed layer test | `dataform/definitions/processed/[table_name]_test.sqlx` |
| Access layer SQLX | `dataform/definitions/access/[table_name].sqlx` |
| Access layer test | `dataform/definitions/access/[table_name]_test.sqlx` |

---

## SQLX Code Rules
- Follow the structure and format defined in `templates/sqlx_template.sqlx`
- type must be: "table" for main file, "test" for test file
- schema must always be: dev_dataform_dataset
- Always use `${ref("table_name")}` to reference source tables
- Always use single quotes for strings in BigQuery SQL → 'value' not "value"
- Never use CURRENT_TIMESTAMP() in any column
- Apply partition key and clustering key from `docs/requirements.md` if specified

---

## Test Rules

### Common Rules (all layers)
- config block must include BOTH: `type: "test"` AND `dataset: "[table_name]"`
- input block must use SQL `SELECT ... UNION ALL` syntax — never JSON format
- Mock data must have at least 5 rows
- Never include `CURRENT_TIMESTAMP()` anywhere in the test file
- The `expected` block MUST use hardcoded literal values — NEVER use `SELECT ... FROM ${ref(...)}`, `SELECT ... FROM ${ self.name }`, or any table reference
- Expected output values must be deterministically calculable from the mock input data
- Always use single quotes for string literals

### Raw Layer (`raw_` prefix)
Additional rules on top of Common Rules:
- EXCLUDE `etl_loaded_at` and any `CURRENT_TIMESTAMP()` columns from both input and expected output
- The expected rows must mirror the input rows (same values) for all included columns
- Add this comment at the top of the test file:
  `-- NOTE: etl_loaded_at excluded from expected output (non-deterministic)`

### Processed Layer (`tmp_` prefix)
Additional rules on top of Common Rules:
- Always compute the expected output by tracing through the SQL logic step by step using the mock input values — never leave expected output empty
- For complex logic (LAG, LEAD, window functions, unit conversions, SCD2, multi-step WITH):
  - Design mock data simple enough to hand-calculate (e.g. small distinct values, clear date sequences)
  - Compute each output column value explicitly from the mock data
- If the SQL contains a bug or ambiguous behavior, add a comment documenting the assumption, then generate expected output matching what the SQL will actually produce
- Add this comment above the expected block:
  `-- NOTE: expected output derived from mock data — verify if transformation logic changes`

### Access Layer (`fct_`, `dim_` prefix)
Additional rules on top of Common Rules:
- Provide a separate `input` block for each table referenced via `${ref()}`
- Design mock data so every JOIN produces exactly 1 matching row per input — no fan-out, no nulls from missing joins
- All input tables must have matching join keys with each other
- For BETWEEN conditions (non-equi JOIN): design timestamps so mock data explicitly falls within the expected range, and add a comment documenting the range:
  `-- NOTE: [timestamp_col] is designed to fall between [start_col] and [end_col]`
- Add this comment at the top of the test file:
  `-- NOTE: mock data designed for deterministic JOIN results`

---

## Output Rules
- Write files directly to disk — do not print file contents to terminal
- Do not wrap output in markdown code blocks or backticks
- Do not ask for confirmation before writing files
- After completing all steps, print a summary of files created grouped by layer

---

## Restrictions
- NEVER guess or invent dataset names — always use ones defined in Project Context
- NEVER include explanation or preamble in generated files
- If the requested table name is not found in `docs/requirements.md`, stop and tell the developer
- If transformation logic is ambiguous, list assumptions at the top of the generated file as comments