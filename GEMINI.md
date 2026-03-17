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

1. Read `docs/requirements.md` to get the full list of all tables and source tables
2. Read `templates/sqlx_template.sqlx` as format reference
3. Create folder structure:
   - `dataform/definitions/sources/`
   - `dataform/definitions/raw/`
   - `dataform/definitions/processed/`
   - `dataform/definitions/access/`
4. For each source table listed in `docs/requirements.md` (tables from the `aiready` dataset):
   - Generate one declaration file per source table → write to `dataform/definitions/sources/[source_table_name].sqlx`
   - NEVER combine multiple source tables into one file
5. For each table in `docs/requirements.md`:
   - Determine correct folder based on table prefix
   - Generate main SQLX → write to correct folder
   - Generate test SQLX following layer-specific test rules → write to same folder
6. Report summary of all files created grouped by layer (include declarations count)

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
| Source declaration | `dataform/definitions/sources/[source_table_name].sqlx` |
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
- Never use CURRENT_TIMESTAMP() in any column — use `TIMESTAMP(CURRENT_DATE())` instead for ETL metadata columns
- Apply partition key and clustering key from `docs/requirements.md` if specified
- NEVER use `SELECT * EXCEPT(col1, col2, ...)` pattern — always list output columns explicitly. If a source has columns that need renaming or transformation, list each output column by name. The `* EXCEPT` pattern fails when the excepted columns are the only columns in the source (produces 0-column output)
- For BigQuery window functions: `LAG(col, offset)` and `LEAD(col, offset)` default value argument MUST be a constant — NEVER use a column reference as the default. Use `COALESCE(LAG(col, n) OVER (...), fallback_col)` instead

### Source Table Declarations
- Each source table (from dataset `aiready`) MUST have its own individual `.sqlx` file in `dataform/definitions/sources/`
- NEVER put multiple `config {}` blocks in one file — Dataform does not support this
- Format for each declaration file:
  ```
  config {
    type: "declaration",
    schema: "aiready",
    name: "table_name"
  }
  ```

---

## Test Rules

### Common Rules (all layers)
- config block must include BOTH: `type: "test"` AND `dataset: "[table_name]"`
- input block must use SQL `SELECT ... UNION ALL` syntax — never JSON format
- Mock data must have at least 5 rows
- Never include `CURRENT_TIMESTAMP()` anywhere in the test file
- The expected output is a bare `SELECT` statement after the last `input {}` block — NEVER wrap it in `expected { ... }` (Dataform does not support that syntax)
- The `expected` output MUST use hardcoded literal values — NEVER use `SELECT ... FROM ${ref(...)}`, `SELECT ... FROM ${ self.name }`, or any table reference
- Expected output values must be deterministically calculable from the mock input data
- Always use single quotes for string literals
- Float precision: when expected value is the result of arithmetic on FLOAT64 inputs (e.g. AVG, division), use the same arithmetic expression in the expected output rather than a decimal literal. Example: use `(0.2 + 0.22) / 2` not `0.21` to avoid IEEE 754 mismatch

### Raw Layer (`raw_` prefix)
Additional rules on top of Common Rules:
- Raw table SQL must use `TIMESTAMP(CURRENT_DATE()) AS etl_loaded_at` and `CURRENT_DATE() AS etl_loaded_date` — NEVER use `CURRENT_TIMESTAMP()` for these columns
- In the test expected output, include `TIMESTAMP(CURRENT_DATE()) AS etl_loaded_at` and `CURRENT_DATE() AS etl_loaded_date` for every row — this matches the table SQL and is stable within a day
- The input `{}` block does NOT include `etl_loaded_at` or `etl_loaded_date` (they are added by the raw table SQL, not sourced from the input)
- All other columns in the expected rows must mirror the input rows exactly (same values)

### Processed Layer (`tmp_` prefix)
Additional rules on top of Common Rules:
- Always compute the expected output by tracing through the SQL logic step by step using the mock input values — never leave expected output empty
- NEVER generate a skeleton or leave expected output as a placeholder
- NEVER use `-- SKELETON: fill in expected output manually` or `-- TODO: verify this expected output manually`
- For complex logic (LAG, LEAD, window functions, unit conversions, SCD2, multi-step WITH):
  - Design mock data simple enough to hand-calculate (e.g. small distinct values, clear date sequences)
  - Compute each output column value explicitly from the mock data
- BigQuery LAG/LEAD constraint: the 3rd argument (default value) MUST be a constant, not a column. Use `COALESCE(LAG(col, 1) OVER (PARTITION BY ... ORDER BY ...), col)` pattern instead of `LAG(col, 1, col) OVER (...)`
- NEVER use `SELECT * EXCEPT(col1, col2, ...)` in the main SQL — list all output columns explicitly. The `* EXCEPT` pattern fails during testing when the excepted columns are the only columns in the mock input (produces 0-column output)
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