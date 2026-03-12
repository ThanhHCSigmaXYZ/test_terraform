# stg_products - Specification Document

## Overview
- **Table Name**: stg_products
- **Dataset**: dev_dataform_dataset
- **Type**: table
- **Description**: This table summarizes product data from the raw_products table, providing aggregated metrics such as total price, record count, and average, maximum, and minimum prices.

## Source
- **Source Table**: raw_products
- **Source Dataset**: aiready

## Output Columns
| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| total_price | FLOAT64 | Sum of all prices from the source table. |
| record_count | INT64 | Total number of records in the source table. |
| average_price | FLOAT64 | Average price of all products. |
| max_price | FLOAT64 | The highest price among all products. |
| min_price | FLOAT64 | The lowest price among all products. |

## Transformation Logic
The SQL transformation logic applied to the source table involves aggregating the data from `raw_products`. It calculates the sum of the `price` column for `total_price`, counts the total number of records for `record_count`, computes the average of the `price` column for `average_price`, and finds the maximum and minimum values of the `price` column for `max_price` and `min_price` respectively.

## Test Cases
### Input Mock Data
Here is the mock data for the `raw_products` source table:
```
| product_id | price |
|------------|-------|
| 1          | 10.00 |
| 2          | 20.00 |
| 3          | 30.00 |
| 4          | 40.00 |
| 5          | 50.00 |
```

### Expected Output
Based on the input mock data, the expected output in the `stg_products` table is:
```
| total_price | record_count | average_price | max_price | min_price |
|-------------|--------------|---------------|-----------|-----------|
| 150.00      | 5            | 30.00         | 50.00     | 10.00     |
```

## Dependencies
- `${ref("raw_products")}` from `aiready`
