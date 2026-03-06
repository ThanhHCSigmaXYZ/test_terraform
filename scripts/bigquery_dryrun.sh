#!/bin/bash
# BigQuery Dry-Run for compiled SQL

echo "Running BigQuery Dry-Run..."
echo ""

COMPILED_DIR="compiled"
PROJECT_ID="ats-theme-dmo-b2bdatacolab"

if [ ! -d "$COMPILED_DIR" ]; then
    echo "No compiled/ directory found"
    echo "Run validate_dataform.py first"
    exit 1
fi

SQL_FILES=$(find $COMPILED_DIR -name "*.sql")

if [ -z "$SQL_FILES" ]; then
    echo "No SQL files in compiled/"
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
        echo "$(basename $sql_file) - Valid"
        ((SUCCESS++))
    else
        echo "$(basename $sql_file) - Invalid"
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
echo "   Success: $SUCCESS"
echo "   Failed: $FAILED"
echo "=================================================="

if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
