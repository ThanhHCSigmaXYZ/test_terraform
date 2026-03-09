#!/bin/bash
# BigQuery Dry-Run for compiled SQL
# Run from: scripts/ folder

echo "Running BigQuery Dry-Run..."
echo ""

COMPILED_DIR="compiled"
PROJECT_ID="ats-theme-dmo-b2bdatacolab"

if [ ! -d "$COMPILED_DIR" ]; then
    echo "ERROR: No $COMPILED_DIR directory found"
    echo "  Make sure you're running from scripts/ folder"
    exit 1
fi

SQL_FILES=$(find $COMPILED_DIR -name "*.sql" 2>/dev/null)

if [ -z "$SQL_FILES" ]; then
    echo "ERROR: No SQL files in $COMPILED_DIR"
    exit 1
fi

FAILED=0
SUCCESS=0

for sql_file in $SQL_FILES; do
    echo "Testing: $(basename $sql_file)"
    
    if bq query \
        --project_id=$PROJECT_ID \
        --use_legacy_sql=false \
        --dry_run \
        < "$sql_file" 2>&1 | grep -q "successfully validated"; then
        echo "  PASS: $(basename $sql_file) - Valid"
        ((SUCCESS++))
    else
        echo "  FAIL: $(basename $sql_file) - Invalid"
        bq query \
            --project_id=$PROJECT_ID \
            --use_legacy_sql=false \
            --dry_run \
            < "$sql_file"
        ((FAILED++))
    fi
    echo ""
done

echo "=================================================="
echo "Dry-Run Results:"
echo "  Success: $SUCCESS"
echo "  Failed: $FAILED"
echo "=================================================="

if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
