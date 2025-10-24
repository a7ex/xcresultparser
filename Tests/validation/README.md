# Cobertura DTD Compliance Testing

This directory contains comprehensive validation tools to ensure `xcresultparser`'s Cobertura XML output is fully compliant with the DTD specification.

## Testing Setup Overview

### 1. DTD Compliance Validation Script (`validate_cobertura_dtd.py`)

**Purpose**: Validates that Cobertura XML output strictly adheres to the coverage-04.dtd specification.

**Key Validations**:
- ✅ DTD compliance using `xmllint`
- ✅ Attribute types (integers for counters, decimals for rates)
- ✅ No scientific notation in decimal values
- ✅ Proper version string (contains "xcresultparser", no "diff_coverage")
- ✅ Integer timestamp (epoch seconds)
- ✅ Zero branch coverage (we don't track branches)
- ✅ Complete XML structure (sources, packages, classes, methods, lines)

**Usage**:
```bash
# Validate a single XML file
python3 validate_cobertura_dtd.py output.xml

# Run comprehensive test suite (recommended)
python3 validate_cobertura_dtd.py --run-all-tests

# Generate and validate in one step
xcresultparser test.xcresult -o cobertura > output.xml && \
python3 validate_cobertura_dtd.py output.xml
```


## Prerequisites

### System Requirements
- Python 3.6+
- `xmllint` (part of libxml2-utils)
  - **macOS**: Usually pre-installed, or `brew install libxml2`
  - **Ubuntu/Debian**: `sudo apt-get install libxml2-utils`
  - **CentOS/RHEL**: `sudo yum install libxml2`

### Build Requirements
```bash
# Build xcresultparser release binary first
swift build -c release
```

## Test Scenarios Covered

### DTD Compliance Tests
1. **Default Output**: Basic Cobertura XML generation
2. **Path Normalization**: Using `--coverage-base-path` and `--sources-root`
3. **Path Exclusions**: Testing `--excluded-paths` functionality
4. **Backward Compatibility**: Old `-p/--project-root` flag support


## Running the Complete Test Suite

### Quick Start
```bash
# Build the project
swift build -c release

# Run DTD validation
python3 Tests/validation/validate_cobertura_dtd.py --run-all-tests
```

### Continuous Integration Setup

Add this to your CI pipeline (GitHub Actions example):

```yaml
name: Cobertura DTD Compliance
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v3
  - name: Build xcresultparser
    run: swift build -c release
  - name: Install xmllint
    run: sudo apt-get update && sudo apt-get install -y libxml2-utils
  - name: Run DTD compliance tests
    run: python3 Tests/validation/validate_cobertura_dtd.py --run-all-tests
```

## Manual Testing with Real xcresult Files

### Generate Test XML Files
```bash
# Basic Cobertura XML
.build/release/xcresultparser Tests/XcresultparserTests/TestAssets/test.xcresult -o cobertura > basic.xml

# With path normalization for CI/CD
.build/release/xcresultparser Tests/XcresultparserTests/TestAssets/test.xcresult \
  -o cobertura \
  --coverage-base-path "/workspace/myproject" \
  --sources-root "." > normalized.xml

# With exclusions
.build/release/xcresultparser Tests/XcresultparserTests/TestAssets/test.xcresult \
  -o cobertura \
  --excluded-paths "Tests,TestSupport" > filtered.xml
```

### Validate Generated Files
```bash
# Validate individual files
python3 Tests/validation/validate_cobertura_dtd.py basic.xml
python3 Tests/validation/validate_cobertura_dtd.py normalized.xml
python3 Tests/validation/validate_cobertura_dtd.py filtered.xml
```

## Expected Output Examples

### ✅ Successful DTD Compliance Validation
```
🔍 Validating DTD compliance with xmllint...
✅ DTD validation passed
🔍 Validating root coverage attributes...
✅ lines-covered: 1234 (integer)
✅ lines-valid: 5678 (integer)
✅ branches-covered: 0 (integer)
✅ branches-valid: 0 (integer)
✅ timestamp: 1609459200 (integer)
✅ line-rate: 0.217391 (decimal)
✅ branch-rate: 0.000000 (decimal)
✅ version: xcresultparser 1.9.3
✅ complexity: 0

🎉 ALL VALIDATIONS PASSED!
   XML is DTD compliant!
```


## Troubleshooting

### Common Issues

1. **Missing xmllint**: Install libxml2-utils package
2. **Binary not found**: Run `swift build -c release` first
3. **Test assets missing**: Ensure you're running from project root
4. **Python version**: Requires Python 3.6+

### Test Failure Analysis

**DTD Validation Failures**:
- Check attribute types (integers vs floats)
- Verify decimal formatting (no scientific notation)
- Confirm version string format
- Validate XML structure completeness


## Maintenance

### Updating DTD
The script automatically downloads the official coverage-04.dtd. If updates are needed, modify the `_download_dtd()` method in `validate_cobertura_dtd.py`.

### Adding New Test Scenarios
1. Add new test cases to the respective scripts
2. Update documentation with new scenarios
3. Ensure comprehensive path coverage for different environments

## DTD Compliance Benefits

Once DTD validation passes, your Cobertura XML is guaranteed to be standards-compliant and compatible with coverage tools that expect proper DTD formatting.

The validation ensures:
- ✅ Proper XML structure and attribute types
- ✅ Standards-compliant Cobertura format
- ✅ Integer timestamps and coverage counters
- ✅ Decimal precision within acceptable limits
- ✅ Valid XML that can be parsed by coverage analysis tools
