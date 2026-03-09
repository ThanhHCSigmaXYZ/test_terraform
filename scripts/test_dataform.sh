#!/bin/bash
# Dataform assertion tests 
echo "Running Dataform Tests..."
echo ""

PROJECT_ID="ats-theme-dmo-b2bdatacolab"
DATASET="staging"
VIEW_NAME="sum_price"
COMPILED_SQL="compiled/sum_price.sql"

# Create staging dataset if not exists
bq mk --dataset --location=asia-northeast1 --project_id="${PROJECT_ID}" "${DATASET}" 2>/dev/null || true

# Create/update view
echo "Creating view..."
bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" < "$COMPILED_SQL"

echo ""
echo "Running tests..."
echo ""

# Test 1: Check for NULL values
echo "Test 1: NULL check"
NULL_COUNT=$(bq query \
    --use_legacy_sql=false \
    --format=csv \
    "SELECT COUNT(*) FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\` 
     WHERE total_price IS NULL OR record_count IS NULL" \
    | tail -n 1)

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
    "SELECT total_price FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\`" \
    | tail -n 1)

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
    "SELECT record_count FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\`" \
    | tail -n 1)

if [ "$RECORD_COUNT" -gt 0 ] 2>/dev/null; then
    echo "  PASS: record_count = $RECORD_COUNT"
else
    echo "  FAIL: record_count = $RECORD_COUNT"
    exit 1
fi

echo ""
echo "All tests passed!"
exit 0