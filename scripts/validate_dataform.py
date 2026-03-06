#!/usr/bin/env python3
"""
Dataform validation script for POC
Validates: JSON, SQLX structure, basic compilation
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
        print("dataform.json not found!")
        return False, None
    
    try:
        config = json.load(open(config_file))
        print(f"dataform.json is valid JSON")
        print(f"   Project: {config.get('defaultDatabase')}")
        print(f"   Schema: {config.get('defaultSchema')}")
        return True, config
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}")
        return False, None

def validate_structure():
    """Validate folder structure"""
    print("\nValidating structure...")
    
    if not Path("dataform/definitions").exists():
        print("definitions/ folder not found!")
        return False
    
    print("definitions/ folder exists")
    return True

def find_sqlx_files():
    """Find all SQLX files"""
    print("\nFinding SQLX files...")
    
    sqlx_files = list(Path("dataform/definitions").rglob("*.sqlx"))
    
    if not sqlx_files:
        print("No SQLX files found")
        return []
    
    print(f"Found {len(sqlx_files)} SQLX file(s):")
    for f in sqlx_files:
        print(f"   - {f}")
    
    return sqlx_files

def compile_simple_sqlx(sqlx_file, config):
    """Simple SQLX compilation - replace ${ref()} only"""
    print(f"\nCompiling {sqlx_file.name}...")
    
    content = sqlx_file.read_text()
    
    # Get config
    project = config.get('defaultDatabase')
    schema = config.get('defaultSchema', 'public')
    
    # Replace ${ref("table")} - uses defaultSchema
    def replace_ref(match):
        table = match.group(1)
        return f'`{project}.{schema}.{table}`'
    
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
    compiled = re.sub(r'config\s*\{[^}]+\}', '', compiled, flags=re.DOTALL)
    
    # Clean up
    compiled = compiled.strip()
    
    if compiled:
        print(f"Compiled successfully")
        return compiled
    else:
        print(f"Compilation failed")
        return None

def validate_sqlx_files(sqlx_files, config):
    """Validate and compile all SQLX files"""
    print("\nValidating SQLX files...")
    
    compiled_sqls = []
    
    for sqlx_file in sqlx_files:
        # Check for unsupported syntax
        content = sqlx_file.read_text()
        
        if '${when(' in content:
            print(f"{sqlx_file.name} uses ${{when()}} - not supported in POC")
        
        if '${self(' in content:
            print(f"{sqlx_file.name} uses ${{self()}} - not supported in POC")
            continue
        
        # Compile
        compiled_sql = compile_simple_sqlx(sqlx_file, config)
        
        if compiled_sql:
            # Save compiled SQL
            output_dir = Path("compiled")
            output_dir.mkdir(exist_ok=True)
            
            output_file = output_dir / f"{sqlx_file.stem}.sql"
            output_file.write_text(compiled_sql)
            
            compiled_sqls.append(output_file)
            print(f"   Saved to: {output_file}")
    
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
        print("\nNo SQLX files to validate")
        sys.exit(0)
    
    # Validate and compile
    compiled_sqls = validate_sqlx_files(sqlx_files, config)
    
    print("\n" + "=" * 50)
    print(f"Validation Complete!")
    print(f"   JSON valid: OK")
    print(f"   Structure valid: OK")
    print(f"   SQLX files: {len(sqlx_files)}")
    print(f"   Compiled: {len(compiled_sqls)}")
    print("=" * 50)
    
    if compiled_sqls:
        print("\nNext: Run BigQuery dry-run")
        sys.exit(0)
    else:
        print("\nNo SQL files compiled")
        sys.exit(1)

if __name__ == "__main__":
    main()
