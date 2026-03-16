# stg_orders - Specification Document

## Overview
- **Table Name**: stg_orders
- **Dataset**: dev_dataform_dataset
- **Type**: table
- **Description**: This table provides aggregated metrics such as total sales, record count, and profit statistics from the raw orders data.

## Source
- **Source Table**: raw_orders
- **Source Dataset**: aiready

## Output Columns
| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| total_sale | NUMERIC | Sum of all sales from the source table. |
| record_count | INT64 | Total number of records in the source table. |
| average_profit | FLOAT64 | Average profit across all records. |
| max_profit_order | FLOAT64 | The highest profit value from a single order. |
| min_profit_order | FLOAT64 | The lowest profit value from a single order. |

## Transformation Logic
The logic calculates aggregate metrics from the `raw_orders` table. It computes the sum of the `sale` column, the total count of records, and the average, maximum, and minimum values of the `profit` column across the entire table.

## Test Cases
### Input Mock Data
```sql
SELECT 1 as order_id, 100 as sale, 20 as profit
UNION ALL
SELECT 2 as order_id, 150 as sale, 30 as profit
UNION ALL
SELECT 3 as order_id, 200 as sale, -10 as profit
UNION ALL
SELECT 4 as order_id, 50 as sale, 5 as profit
UNION ALL
SELECT 5 as order_id, 120 as sale, 25 as profit
```

### Expected Output
```sql
SELECT 620 as total_sale, 5 as record_count, 14 as average_profit, 30 as max_profit_order, -10 as min_profit_order
```

## Dependencies
- `${ref("raw_orders")}` from `aiready`
