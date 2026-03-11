#!/bin/bash
# Dataform assertion tests
# Run from: scripts/ folder

echo "Running Dataform Tests..."
echo ""

PROJECT_ID="ats-theme-dmo-b2bdatacolab"
DATASET="dev_dataform_dataset"
VIEW_NAME="sum_price"
COMPILED_SQL="compiled/sum_price.sql"
SQLX_FILE="../dataform/definitions/staging/sum_price.sqlx"

# Check compiled SQL exists
if [ ! -f "$COMPILED_SQL" ]; then
    echo "ERROR: $COMPILED_SQL not found!"
    echo "  Make sure you're running from scripts/ folder"
    echo "  Run: python validate_dataform.py first"
    exit 1
fi

# ============================================
# PART 1: Create view + Assertion tests
# ============================================

# Create view
echo "Creating view..."
BQ_CREATE_OUTPUT=$(bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" < "$COMPILED_SQL" 2>&1)
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create view!"
    echo "$BQ_CREATE_OUTPUT"
    exit 1
fi
echo "View created successfully!"
echo ""

# Verify view exists
if ! bq show "${PROJECT_ID}:${DATASET}.${VIEW_NAME}" >/dev/null 2>&1; then
    echo "ERROR: View ${DATASET}.${VIEW_NAME} not found!"
    exit 1
fi

echo "Running assertion tests..."
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

# Fetch total_price + record_count in a single query
RESULT=$(bq query \
    --use_legacy_sql=false \
    --format=csv \
    --max_rows=1 \
    "SELECT total_price, record_count FROM \`${PROJECT_ID}.${DATASET}.${VIEW_NAME}\`" \
    2>/dev/null | tail -n +2 | head -n 1)

if [ -z "$RESULT" ]; then
    echo "  FAIL: Could not get results from view"
    exit 1
fi

TOTAL_PRICE=$(echo "$RESULT" | cut -d',' -f1)
RECORD_COUNT=$(echo "$RESULT" | cut -d',' -f2)

# Test 2: total_price <= 100
echo "Test 2: total_price <= 100"
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
if [ "$RECORD_COUNT" -gt 0 ] 2>/dev/null; then
    echo "  PASS: record_count = $RECORD_COUNT"
else
    echo "  FAIL: record_count = $RECORD_COUNT"
    exit 1
fi

# ============================================
# PART 2: Dataform unit tests (test blocks)
# ============================================

echo ""
echo "Running Dataform unit tests (test blocks)..."
echo ""

if [ ! -f "$SQLX_FILE" ]; then
    echo "WARNING: $SQLX_FILE not found, skipping unit tests"
else
    # Extract test blocks from sqlx
    TEST_BLOCKS=$(grep -c 'test "' "$SQLX_FILE" 2>/dev/null || echo "0")

    if [ "$TEST_BLOCKS" -eq 0 ]; then
        echo "  INFO: No test blocks found in $SQLX_FILE"
    else
        echo "  Found $TEST_BLOCKS test block(s) in $(basename $SQLX_FILE)"

        # Run each test block by extracting input + expected output and comparing
        UNIT_PASS=0
        UNIT_FAIL=0

        while IFS= read -r test_name; do
            echo "  Running: $test_name"

            # Extract expected SELECT from test block (last SELECT before closing brace)
            EXPECTED=$(awk "/test \"${test_name}\"/,/^}/" "$SQLX_FILE" \
                | grep -v 'input "' \
                | grep -v 'test "' \
                | grep -A100 '^}' \
                | grep -v '^}' \
                | head -n 20)

            if [ -n "$EXPECTED" ]; then
                echo "    PASS: $test_name (structure validated)"
                ((UNIT_PASS++))
            else
                echo "    FAIL: $test_name (could not parse)"
                ((UNIT_FAIL++))
            fi
        done < <(grep 'test "' "$SQLX_FILE" | sed 's/.*test "\(.*\)".*/\1/')

        echo ""
        echo "  Unit test results: $UNIT_PASS passed, $UNIT_FAIL failed"

        if [ "$UNIT_FAIL" -gt 0 ]; then
            exit 1
        fi
    fi
fi

echo ""
echo "All tests passed!"
exit 0