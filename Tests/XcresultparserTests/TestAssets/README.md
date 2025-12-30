# Test Assets and Fixtures

This directory contains test data files used by xcresultparser's test suite and validation scripts.

## XCResult Bundle Files

### `test.xcresult`
- **Purpose**: Primary test bundle for basic functionality testing
- **Content**: Contains typical iOS app test results with coverage data
- **Usage**: Used by most unit tests and DTD compliance validation

### `test_merged.xcresult`
- **Purpose**: Tests merged test results functionality
- **Content**: Combined results from multiple test runs

### `test_repeated.xcresult`
- **Purpose**: Tests handling of repeated test scenarios
- **Content**: Results with repeated test cases

### `resultWithCompileError.xcresult`
- **Purpose**: Tests error handling for compile failures
- **Content**: XCResult bundle containing compilation errors

## Expected Output Files

### Cobertura XML Files

#### `cobertura.xml` (Legacy - Non-DTD Compliant)
- **Status**: ⚠️ **DEPRECATED** - Contains DTD compliance issues
- **Issues**:
  - Float values in integer attributes (`branches-covered="1.0"`)
  - Float timestamp (`timestamp="1672825221.218"`)
  - Non-standard version string (`version="diff_coverage 0.1"`)
  - Incorrect branch coverage values
- **Usage**: Used for regression testing to ensure old format is avoided

#### `cobertura_dtd_compliant.xml` (Current - DTD Compliant) ✅
- **Status**: ✅ **CURRENT** - Fully DTD compliant
- **Features**:
  - Integer coverage counters
  - Integer timestamp
  - Proper version string (`xcresultparser 1.9.3`)
  - Zero branch coverage (as expected)
  - 6-decimal precision for rates
- **Usage**: Reference for DTD compliance validation

#### `cobertura_with_base_path.xml` ✅
- **Purpose**: Tests `--coverage-base-path` and `--sources-root` flags
- **CLI Command**: 
  ```bash
  xcresultparser test.xcresult -o cobertura \
    --coverage-base-path /ci/workspace \
    --sources-root .
  ```
- **Features**: Demonstrates path normalization for CI/CD environments

#### `cobertura_with_sources_root.xml` ✅
- **Purpose**: Tests `--sources-root` flag functionality
- **CLI Command**:
  ```bash
  xcresultparser test.xcresult -o cobertura --sources-root src
  ```
- **Features**: Shows custom source root configuration

#### `coberturaExcludingDirectory.xml`
- **Purpose**: Tests directory exclusion functionality
- **Usage**: Validates `--excluded-path` flag behavior

### JUnit XML Files

#### `junit.xml`
- **Purpose**: Reference JUnit XML output format
- **Usage**: Unit tests for JUnit format validation

#### `junit_merged.xml`
- **Purpose**: JUnit output from merged test results
- **Usage**: Tests merged results in JUnit format

#### `junit_repeated.xml`
- **Purpose**: JUnit output with repeated test cases
- **Usage**: Tests handling of repeated tests in JUnit format

### SonarQube XML Files

#### `sonarTestExecution.xml`
- **Purpose**: SonarQube test execution format
- **Usage**: Unit tests for SonarQube integration

#### `sonarTestExecutionWithProjectRootAbsolute.xml`
- **Purpose**: SonarQube format with absolute project root
- **Usage**: Tests absolute path handling in SonarQube format

#### `sonarTestExecutionWithProjectRootRelative.xml`
- **Purpose**: SonarQube format with relative project root
- **Usage**: Tests relative path handling in SonarQube format

## Usage in Tests

### Unit Tests
The test assets are used extensively in `XcresultparserTests.swift`:

```swift
// Example usage
let testBundle = Bundle.module
let xcresultURL = testBundle.url(forResource: "test", withExtension: "xcresult")!
```

### DTD Compliance Validation
The validation script uses these assets to test various scenarios:

```bash
# Test default output
python3 Tests/validation/validate_cobertura_dtd.py --run-all-tests

# Validate specific fixture
python3 Tests/validation/validate_cobertura_dtd.py Tests/XcresultparserTests/TestAssets/cobertura_dtd_compliant.xml
```

### CI/CD Integration
GitHub Actions workflows use these assets for automated testing:

```yaml
- name: Run DTD compliance tests
  run: python3 Tests/validation/validate_cobertura_dtd.py --run-all-tests
```

## Creating New Test Assets

### Generate New Cobertura Files
To create new reference files after making changes:

```bash
# Basic DTD-compliant output
.build/release/xcresultparser Tests/XcresultparserTests/TestAssets/test.xcresult \
  -o cobertura > new_reference.xml

# With path normalization
.build/release/xcresultparser Tests/XcresultparserTests/TestAssets/test.xcresult \
  -o cobertura \
  --coverage-base-path /workspace \
  --sources-root . > normalized_reference.xml

# Validate new files
python3 Tests/validation/validate_cobertura_dtd.py new_reference.xml
```

### Adding New XCResult Bundles
When adding new `.xcresult` test data:

1. **Place in this directory**: `Tests/XcresultparserTests/TestAssets/`
2. **Update test references**: Modify test files to use the new bundle
3. **Generate expected outputs**: Create corresponding XML reference files
4. **Validate compliance**: Run DTD validation on generated outputs
5. **Update documentation**: Add description to this README

## Maintenance

### Updating Reference Files
When the XML generation logic changes, update reference files:

```bash
# Regenerate all Cobertura reference files
make update-test-fixtures  # If Makefile target exists

# Or manually:
.build/release/xcresultparser Tests/XcresultparserTests/TestAssets/test.xcresult -o cobertura > Tests/XcresultparserTests/TestAssets/cobertura_dtd_compliant.xml
```

### Validating All Assets
Run comprehensive validation on all reference files:

```bash
# Validate all XML files in the directory
for file in Tests/XcresultparserTests/TestAssets/*.xml; do
  if [[ "$file" == *"cobertura"* ]]; then
    echo "Validating $file..."
    python3 Tests/validation/validate_cobertura_dtd.py "$file" || echo "⚠️ Validation failed for $file"
  fi
done
```

## File Size Considerations

Some test assets may be large:
- `.xcresult` bundles can be several MB
- Generated XML files may be large for complex projects
- Keep test assets focused and minimal when possible

## Version Control

- ✅ **Include**: Small reference XML files for comparison testing
- ✅ **Include**: Essential `.xcresult` bundles (with LFS if large)
- ❌ **Exclude**: Temporary generated files during testing
- ❌ **Exclude**: Large intermediate files not needed for tests

## Troubleshooting

### Missing Test Assets
If test assets are missing or corrupted:

1. Check git LFS status: `git lfs status`
2. Pull LFS files: `git lfs pull`
3. Regenerate reference files if needed
4. Validate using the DTD compliance script

### DTD Compliance Issues
If reference files fail DTD validation:

1. Regenerate with current xcresultparser build
2. Check for changes in DTD requirements
3. Update validation script if DTD specification changed
4. Ensure proper integer/decimal formatting

This directory maintains backward compatibility while ensuring all new generated outputs meet DTD compliance standards.