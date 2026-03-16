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

## Workflow
When a developer asks to create a Dataform table (in any language, any phrasing),
always follow these steps automatically without asking for confirmation:

1. Read the requirement file from `requirements/[table_name].txt`
2. Read `templates/document_template.md` as the spec format reference
3. Generate spec document → write to `docs/[table_name]_spec.md`
4. Read the spec document + `templates/sqlx_template.sqlx` as reference
5. Generate main SQLX → write to `dataform/definitions/staging/[table_name].sqlx`
6. Generate test SQLX → write to `dataform/definitions/staging/[table_name]_test.sqlx`
7. Report to developer which files were created

### Trigger phrases (any of these should start the workflow)
- "[name]のテーブルを作成して"
- "[name]のdataformを生成して"
- "[name]のテーブルを作って"
- "[name]を生成して" etc...

---

## File Naming Convention
| File | Path |
|------|------|
| Requirement | `requirements/[table_name].txt` |
| Spec document | `docs/[table_name]_spec.md` |
| Main SQLX | `dataform/definitions/staging/[table_name].sqlx` |
| Test SQLX | `dataform/definitions/staging/[table_name]_test.sqlx` |

---

## SQLX Code Rules
- type must be: "table" for main file, "test" for test file
- schema must always be: dev_dataform_dataset
- Always use `${ref("table_name")}` to reference source tables
- Never use CURRENT_TIMESTAMP() in any column

## Test File Rules
- config block must include BOTH: `type: "test"` AND `dataset: "[table_name]"`
- input block must use SQL SELECT UNION ALL syntax (not JSON format)
- Expected output must only include columns defined in the main SQLX SELECT
- Mock data must have at least 5 rows
- Expected output values must be manually calculated and correct

---

## Output Rules
- Write files directly to disk — do not print file contents to terminal
- Do not wrap output in markdown code blocks or backticks
- Do not ask for confirmation before writing files
- After completing all steps, print a summary of files created

---

## Restrictions
- NEVER guess or invent dataset names — always use ones defined in Project Context
- NEVER include explanation or preamble in generated files
- NEVER skip the spec document step — always generate doc before SQLX
- If requirement file does not exist, stop and tell the developer
- If requirement is ambiguous, list assumptions at the top of the spec document