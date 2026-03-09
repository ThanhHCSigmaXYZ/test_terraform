#!/bin/bash
# Dataform assertion tests
# Run from: scripts/ folder

set -e

echo "Running Dataform Tests..."
echo ""

PROJECT_ID="ats-theme-dmo-b2bdatacolab"
DATASET="dev_dataform_dataset"
VIEW_NAME="sum_price"
COMPILED_SQL="compiled/sum_price.sql"

# Check compiled SQL exists
if [ ! -f "$COMPILED_SQL" ]; then
    echo "ERROR: $COMPILED_SQL not found!"
    echo "  Make sure you're running from scripts/ folder"
    echo "  Run: python validate_dataform.py first"
    exit 1
fi

# Create view
echo "Creating view..."
if ! bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" < "$COMPILED_SQL"; then
    echo "ERROR: Failed to create view!"
    exit 1
fi

echo "View created successfully!"
echo ""

# Verify view exists
if ! bq show "${PROJECT_ID}:${DATASET}.${VIEW_NAME}" >/dev/null 2>&1; then
    echo "ERROR: View ${DATASET}.${VIEW_NAME} not found!"
    exit 1
fi

echo "Running tests..."
echo ""

# Test 1: NULL check
echo "Test 1: NULL check"
NULL_COUNT=$(bq query \
    --use_legacy_sql=false \
    --format=csv \
    --max_rows=1 \
    "SELECT COUNT(*) as null_count FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\` WHERE total_price IS NULL OR record_count IS NULL" \
    2>/dev/null | tail -n +2 | head -n 1)

if [ "$NULL_COUNT" = "0" ]; then
    echo "  PASS: No NULL values"
else
    echo "  FAIL: Found $NULL_COUNT NULL values"
    exit 1
fi

# Test 2: total_price <= 100
echo "Test 2: total_price <= 100"
TOTAL_PRICE=$(bq query \
    --use_legacy_sql=false \
    --format=csv \
    --max_rows=1 \
    "SELECT total_price FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\`" \
    2>/dev/null | tail -n +2 | head -n 1)

if [ -z "$TOTAL_PRICE" ]; then
    echo "  FAIL: Could not get total_price"
    exit 1
fi

if awk -v val="$TOTAL_PRICE" 'BEGIN { exit !(val <= 100) }'; then
    echo "  PASS: total_price = $TOTAL_PRICE"
else
    echo "  FAIL: total_price = $TOTAL_PRICE (exceeds 100)"
    exit 1
fi

# Test 3: total_price >= 0
echo "Test 3: total_price >= 0"
if awk -v val="$TOTAL_PRICE" 'BEGIN { exit !(val >= 0) }'; then
    echo "  PASS: total_price = $TOTAL_PRICE"
else
    echo "  FAIL: total_price = $TOTAL_PRICE (negative)"
    exit 1
fi

# Test 4: record_count > 0
echo "Test 4: record_count > 0"
RECORD_COUNT=$(bq query \
    --use_legacy_sql=false \
    --format=csv \
    --max_rows=1 \
    "SELECT record_count FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\`" \
    2>/dev/null | tail -n +2 | head -n 1)

if [ -z "$RECORD_COUNT" ]; then
    echo "  FAIL: Could not get record_count"
    exit 1
fi

if [ "$RECORD_COUNT" -gt 0 ] 2>/dev/null; then
    echo "  PASS: record_count = $RECORD_COUNT"
else
    echo "  FAIL: record_count = $RECORD_COUNT"
    exit 1
fi

echo ""
echo "All tests passed!"
exit 0
