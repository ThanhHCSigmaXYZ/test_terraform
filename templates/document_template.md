# [TABLE_NAME] - Specification Document

## Overview
- **Table Name**: [TABLE_NAME]
- **Dataset**: [DATASET_NAME]
- **Type**: [table/view]
- **Description**: [Brief description of what this table does]

## Source
- **Source Table**: [SOURCE_TABLE_NAME]
- **Source Dataset**: [SOURCE_DATASET_NAME]

## Output Columns
| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| [column_name] | [data_type] | [description] |

## Transformation Logic
[Describe the SQL transformation logic applied to the source table]

## Test Cases
### Input Mock Data
[Describe the mock data to be used for testing]

### Expected Output
[Describe the expected output after transformation]

## Dependencies
- `${ref("[SOURCE_TABLE_NAME]")}` from `[SOURCE_DATASET_NAME]`
