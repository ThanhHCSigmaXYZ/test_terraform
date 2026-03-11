#!/usr/bin/env python3
"""
Dataform validation script for POC
Compiles SQLX to SQL with CREATE VIEW/TABLE statements
Run from: scripts/ folder
Output: scripts/compiled/*.sql
"""

import json
import re
import sys
from pathlib import Path

def validate_json():
    """Validate dataform.json"""
    print("Validating dataform.json...")
    
    config_file = Path("dataform/dataform.json")
    
    if not config_file.exists():
        print("ERROR: dataform.json not found")
        print("  Make sure you're running from scripts/folder")
        return False, None
    
    try:
        config = json.load(open(config_file))
        print("OK: dataform.json is valid JSON")
        print("  Project:", config.get('defaultDatabase'))
        print("  Schema:", config.get('defaultSchema'))
        return True, config
    except json.JSONDecodeError as e:
        print("ERROR: Invalid JSON:", e)
        return False, None

def validate_structure():
    """Validate folder structure"""
    print("\nValidating structure...")
    
    definitions_dir = Path("dataform/definitions")
    
    if not definitions_dir.exists():
        print("ERROR: definitions/ folder not found")
        return False
    
    print("OK: definitions/ folder exists")
    return True

def find_sqlx_files():
    """Find all SQLX files (excluding test files)"""
    print("\nFinding SQLX files...")
    
    definitions_dir = Path("dataform/definitions")
    all_sqlx_files = list(definitions_dir.rglob("*.sqlx"))

    # Exclude *_test.sqlx — these are Dataform unit test files, not compiled to SQL
    sqlx_files = [f for f in all_sqlx_files if not f.stem.endswith("_test")]
    excluded = [f for f in all_sqlx_files if f.stem.endswith("_test")]

    if excluded:
        print(f"Skipped {len(excluded)} test file(s) (will not be dry-run):")
        for f in excluded:
            print("  -", f)

    if not sqlx_files:
        print("WARNING: No SQLX files found")
        return []
    
    print("Found", len(sqlx_files), "SQLX file(s):")
    for f in sqlx_files:
        print("  -", f)
    
    return sqlx_files

def strip_config_block(compiled):
    """Remove config { ... } block from SQLX content"""
    config_start = compiled.find('config')
    if config_start != -1:
        brace_pos = compiled.find('{', config_start)
        if brace_pos != -1:
            brace_count = 0
            i = brace_pos
            while i < len(compiled):
                if compiled[i] == '{':
                    brace_count += 1
                elif compiled[i] == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        compiled = compiled[:config_start] + compiled[i+1:]
                        break
                i += 1
    return compiled

def strip_test_blocks(compiled):
    """Remove test \"...\" { ... } blocks (Dataform unit test syntax - not valid SQL)"""
    compiled = re.sub(
        r'test\s+"[^"]+"\s*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        '',
        compiled,
        flags=re.DOTALL
    )
    return compiled

def compile_simple_sqlx(sqlx_file, config):
    """Simple SQLX compilation - replace ${ref()} and add CREATE VIEW/TABLE"""
    print("\nCompiling", sqlx_file.name, "...")
    
    content = sqlx_file.read_text()
    
    # Get config values
    project = config.get('defaultDatabase')
    default_schema = config.get('defaultSchema', 'public')
    
    # Parse config block to extract schema and type
    schema = default_schema
    view_type = "view"
    
    # Extract schema from config if present
    schema_match = re.search(r'schema:\s*"([^"]+)"', content)
    if schema_match:
        schema = schema_match.group(1)
    
    # Extract type from config if present
    type_match = re.search(r'type:\s*"([^"]+)"', content)
    if type_match:
        view_type = type_match.group(1)
    
    # Replace ${ref("table")}
    def replace_ref(match):
        table = match.group(1)
        return f'`{project}.{default_schema}.{table}`'
    
    compiled = re.sub(r'\$\{ref\("([^"]+)"\)\}', replace_ref, content)
    
    # Replace ${ref("schema", "table")}
    def replace_ref_two(match):
        schema_name = match.group(1)
        table_name = match.group(2)
        return f'`{project}.{schema_name}.{table_name}`'
    
    compiled = re.sub(
        r'\$\{ref\("([^"]+)",\s*"([^"]+)"\)\}',
        replace_ref_two,
        compiled
    )
    
    # Remove config block
    compiled = strip_config_block(compiled)

    # Remove test blocks (Dataform unit test syntax - not valid SQL)
    compiled = strip_test_blocks(compiled)
    
    # Clean up whitespace
    compiled = compiled.strip()
    lines = [line for line in compiled.split('\n') if line.strip()]
    compiled = '\n'.join(lines)
    
    # Get view/table name from filename
    view_name = sqlx_file.stem
    full_path = f'`{project}.{schema}.{view_name}`'
    
    # Add CREATE statement
    if view_type == "view":
        compiled = f"CREATE OR REPLACE VIEW {full_path} AS\n{compiled}"
    elif view_type == "table":
        compiled = f"CREATE OR REPLACE TABLE {full_path} AS\n{compiled}"
    else:
        compiled = f"CREATE OR REPLACE VIEW {full_path} AS\n{compiled}"
    
    if compiled and ('SELECT' in compiled or 'CREATE' in compiled):
        print("OK: Compiled successfully")
        print("  Type:", view_type)
        print("  Target:", schema + "." + view_name)
        return compiled
    else:
        print("ERROR: Compilation failed")
        return None

def validate_sqlx_files(sqlx_files, config):
    """Validate and compile all SQLX files"""
    print("\nValidating SQLX files...")
    
    compiled_sqls = []
    
    for sqlx_file in sqlx_files:
        content = sqlx_file.read_text()
        
        if '${when(' in content:
            print("WARNING:", sqlx_file.name, "uses ${when()} - not supported in POC")
        
        if '${self(' in content:
            print("WARNING:", sqlx_file.name, "uses ${self()} - not supported in POC")
            continue
        
        # Compile
        compiled_sql = compile_simple_sqlx(sqlx_file, config)
        
        if compiled_sql:
            # Save to compiled/ folder (relative to scripts/)
            output_dir = Path("compiled")
            output_dir.mkdir(parents=True, exist_ok=True)
            
            output_file = output_dir / f"{sqlx_file.stem}.sql"
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(compiled_sql)
            
            compiled_sqls.append(output_file)
            print("  Saved to:", output_file)
    
    return compiled_sqls

def main():
    """Main validation"""
    print("=" * 50)
    print("Dataform Validation (POC)")
    print("=" * 50)
    
    # Validate JSON
    json_valid, config = validate_json()
    if not json_valid:
        sys.exit(1)
    
    # Validate structure
    if not validate_structure():
        sys.exit(1)
    
    # Find SQLX files
    sqlx_files = find_sqlx_files()
    if not sqlx_files:
        print("\nWARNING: No SQLX files to validate")
        sys.exit(0)
    
    # Validate and compile
    compiled_sqls = validate_sqlx_files(sqlx_files, config)
    
    print("\n" + "=" * 50)
    print("Validation Complete!")
    print("  JSON valid: OK")
    print("  Structure valid: OK")
    print("  SQLX files:", len(sqlx_files))
    print("  Compiled:", len(compiled_sqls))
    print("=" * 50)
    
    if compiled_sqls:
        print("\nNext: Run BigQuery dry-run and tests")
        sys.exit(0)
    else:
        print("\nWARNING: No SQL files compiled")
        sys.exit(1)

if __name__ == "__main__":
    main()