# stg_cars - Specification Document

## Overview
- **Table Name**: stg_cars
- **Dataset**: dev_dataform_dataset
- **Type**: table
- **Description**: This table calculates aggregate sales and profit metrics from raw order data.

## Source
- **Source Table**: raw_orders
- **Source Dataset**: aiready

## Output Columns
| Column Name | Data Type | Description |
|---|---|---|
| total_sale | FLOAT64 | Sum of all sold units in the sale column |
| record_count | INT64 | Count of all records in the table |
| average_profit | FLOAT64 | Average of profit among all sale data |
| max_profit_order | FLOAT64 | The highest profit among the sale data |
| min_profit_order | FLOAT64 | The lowest profit among the sale data |

## Transformation Logic
The transformation aggregates data from the `raw_orders` table to produce key business metrics. It calculates the total sum of sales, the total count of records, the average profit, and identifies the maximum and minimum profit values across all orders.

## Test Cases
### Input Mock Data
```sql
SELECT 'CA-2021-10001' AS order_id, 261.96 AS sale, 41.9136 AS profit UNION ALL
SELECT 'CA-2021-10002' AS order_id, 731.94 AS sale, 219.582 AS profit UNION ALL
SELECT 'US-2022-20003' AS order_id, 14.62 AS sale, -5.4321 AS profit UNION ALL
SELECT 'CA-2022-30004' AS order_id, 957.5775 AS sale, 145.92 AS profit UNION ALL
SELECT 'US-2023-40005' AS order_id, 22.368 AS sale, 2.5164 AS profit
```

### Expected Output
```sql
SELECT 1988.4655 AS total_sale, 5 AS record_count, 80.90038 AS average_profit, 219.582 AS max_profit_order, -5.4321 AS min_profit_order
```

## Dependencies
- `${ref("raw_orders")}` from `aiready`
