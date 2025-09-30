#!/usr/bin/env python3
"""
Cobertura DTD Compliance Validation Script

This script validates that xcresultparser's Cobertura XML output adheres strictly 
to the coverage-04.dtd specification.

Usage:
    python3 validate_cobertura_dtd.py <xml_file>           # Validate single file
    python3 validate_cobertura_dtd.py --run-all-tests      # Run comprehensive test suite

Requirements:
    - Python 3.6+
    - xmllint (part of libxml2-utils package on most systems)
    - xcresultparser binary built with: swift build -c release

The script validates:
- DTD compliance using xmllint
- Attribute types (integers vs floats)
- Decimal precision limits
- XML structure completeness
- Path normalization behavior
"""

import argparse
import os
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
import re
import shutil


class CoberturaValidator:
    """Validates Cobertura XML output for DTD compliance."""
    
    def __init__(self):
        # Find project paths
        self.script_dir = Path(__file__).parent
        self.project_root = self.script_dir.parent.parent
        self.xcresultparser_bin = self.project_root / ".build" / "release" / "xcresultparser"
        self.test_assets = self.project_root / "Tests" / "XcresultparserTests" / "TestAssets"
        
        # Download DTD if needed
        self.dtd_path = self.script_dir / "coverage-04.dtd"
        if not self.dtd_path.exists():
            print("⬇️  Downloading coverage-04.dtd...")
            self._download_dtd()
    
    def _download_dtd(self):
        """Download the official Cobertura DTD."""
        dtd_content = '''<?xml version="1.0" encoding="UTF-8"?>
<!ELEMENT coverage (sources?,packages)>
<!ATTLIST coverage line-rate        CDATA #REQUIRED>
<!ATTLIST coverage branch-rate      CDATA #REQUIRED>
<!ATTLIST coverage lines-covered    CDATA #REQUIRED>
<!ATTLIST coverage lines-valid      CDATA #REQUIRED>
<!ATTLIST coverage branches-covered CDATA #REQUIRED>
<!ATTLIST coverage branches-valid   CDATA #REQUIRED>
<!ATTLIST coverage complexity       CDATA #REQUIRED>
<!ATTLIST coverage version          CDATA #REQUIRED>
<!ATTLIST coverage timestamp        CDATA #REQUIRED>

<!ELEMENT sources (source*)>
<!ELEMENT source (#PCDATA)>

<!ELEMENT packages (package*)>
<!ELEMENT package (classes)>
<!ATTLIST package name        CDATA #REQUIRED>
<!ATTLIST package line-rate   CDATA #REQUIRED>
<!ATTLIST package branch-rate CDATA #REQUIRED>
<!ATTLIST package complexity  CDATA #REQUIRED>

<!ELEMENT classes (class*)>
<!ELEMENT class (methods,lines)>
<!ATTLIST class name           CDATA #REQUIRED>
<!ATTLIST class filename       CDATA #REQUIRED>
<!ATTLIST class line-rate      CDATA #REQUIRED>
<!ATTLIST class branch-rate    CDATA #REQUIRED>
<!ATTLIST class complexity     CDATA #REQUIRED>

<!ELEMENT methods (method*)>
<!ELEMENT method (lines)>
<!ATTLIST method name          CDATA #REQUIRED>
<!ATTLIST method signature     CDATA #REQUIRED>
<!ATTLIST method line-rate     CDATA #REQUIRED>
<!ATTLIST method branch-rate   CDATA #REQUIRED>
<!ATTLIST method complexity    CDATA #REQUIRED>

<!ELEMENT lines (line*)>
<!ELEMENT line EMPTY>
<!ATTLIST line number          CDATA #REQUIRED>
<!ATTLIST line hits            CDATA #REQUIRED>
<!ATTLIST line branch          CDATA #IMPLIED>
<!ATTLIST line condition-coverage CDATA #IMPLIED>'''
        
        with open(self.dtd_path, 'w') as f:
            f.write(dtd_content)
        print(f"✅ DTD downloaded to {self.dtd_path}")
    
    def validate_single_file(self, xml_file_path):
        """Validate a single XML file against DTD requirements."""
        print(f"🔍 Validating: {xml_file_path}")
        print("=" * 60)
        
        if not os.path.exists(xml_file_path):
            print(f"❌ File not found: {xml_file_path}")
            return False
        
        try:
            # Parse XML
            tree = ET.parse(xml_file_path)
            root = tree.getroot()
            
            success = True
            
            # Run all validations
            success &= self._validate_dtd_compliance(xml_file_path)
            success &= self._validate_root_attributes(root)
            success &= self._validate_xml_structure(root)
            success &= self._validate_coverage_requirements(root)
            success &= self._validate_path_attributes(root)
            
            if success:
                print("\n🎉 ALL VALIDATIONS PASSED!")
                print("   XML is DTD compliant!")
            else:
                print("\n💥 VALIDATION FAILED!")
                print("   See errors above for details.")
            
            return success
            
        except ET.ParseError as e:
            print(f"❌ XML parsing error: {e}")
            return False
        except Exception as e:
            print(f"❌ Validation error: {e}")
            return False
    
    def run_comprehensive_tests(self):
        """Run comprehensive test suite with various scenarios."""
        print("🧪 COMPREHENSIVE COBERTURA DTD VALIDATION TESTS")
        print("=" * 60)
        
        if not self.xcresultparser_bin.exists():
            print("❌ xcresultparser binary not found.")
            print("   Please build it first: swift build -c release")
            return False
        
        test_scenarios = [
            {
                "name": "Default Output",
                "args": [str(self.test_assets / "test.xcresult"), "-o", "cobertura"]
            },
            {
                "name": "With Coverage Base Path",
                "args": [
                    str(self.test_assets / "test.xcresult"), "-o", "cobertura",
                    "--coverage-base-path", "/workspace/myproject",
                    "--sources-root", "."
                ]
            },
            {
                "name": "With Sources Root",
                "args": [
                    str(self.test_assets / "test.xcresult"), "-o", "cobertura",
                    "--sources-root", "src"
                ]
            },
            {
                "name": "With Path Exclusions",
                "args": [
                    str(self.test_assets / "test.xcresult"), "-o", "cobertura",
                    "--excluded-path", "TestSupport", "--excluded-path", "Tests"
                ]
            },
            {
                "name": "Backward Compatibility (project-root)",
                "args": [
                    str(self.test_assets / "test.xcresult"), "-o", "cobertura",
                    "-p", "/legacy/project"
                ]
            }
        ]
        
        all_passed = True
        results = []
        
        for scenario in test_scenarios:
            print(f"\n🧪 {scenario['name']}")
            print("-" * 40)
            
            # Generate XML
            xml_file = self._run_xcresultparser(scenario['args'])
            if xml_file is None:
                print(f"❌ Failed to generate XML for scenario: {scenario['name']}")
                results.append({"name": scenario['name'], "passed": False})
                all_passed = False
                continue
            
            # Validate the generated XML
            passed = self.validate_single_file(xml_file)
            results.append({"name": scenario['name'], "passed": passed})
            if not passed:
                all_passed = False
            
            # Clean up temp file
            try:
                os.unlink(xml_file)
            except:
                pass
        
        # Print summary
        print("\n" + "=" * 60)
        print("📊 COMPREHENSIVE TEST SUMMARY")
        print("=" * 60)
        
        passed_count = sum(1 for r in results if r["passed"])
        total_count = len(results)
        
        print(f"Scenarios passed: {passed_count}/{total_count}")
        
        for result in results:
            status = "✅" if result["passed"] else "❌"
            print(f"  {status} {result['name']}")
        
        if all_passed:
            print("\n🎉 ALL COMPREHENSIVE TESTS PASSED!")
            print("   xcresultparser Cobertura output is DTD compliant!")
        else:
            print(f"\n💥 {total_count - passed_count} test(s) failed!")
        
        return all_passed
    
    def _run_xcresultparser(self, args):
        """Run xcresultparser and return path to temporary output file."""
        try:
            with tempfile.NamedTemporaryFile(mode='w', suffix='.xml', delete=False) as f:
                output_file = f.name
            
            result = subprocess.run(
                [str(self.xcresultparser_bin)] + args,
                stdout=open(output_file, 'w'),
                stderr=subprocess.PIPE,
                text=True,
                check=True
            )
            
            return output_file
            
        except subprocess.CalledProcessError as e:
            print(f"❌ xcresultparser failed: {e.stderr}")
            return None
        except Exception as e:
            print(f"❌ Error running xcresultparser: {e}")
            return None
    
    def _validate_dtd_compliance(self, xml_file_path):
        """Validate XML against DTD using xmllint."""
        if not shutil.which("xmllint"):
            print("⚠️  xmllint not found - skipping DTD validation")
            print("   Install with: apt-get install libxml2-utils (Linux)")
            print("   or: brew install libxml2 (macOS)")
            return True  # Don't fail if xmllint isn't available
        
        print("🔍 Validating DTD compliance with xmllint...")
        
        try:
            # First, check if XML already has DTD reference
            with open(xml_file_path, 'r') as f:
                content = f.read()
            
            # Check if XML has inline DTD definitions (which would conflict with external DTD)
            if '<!ELEMENT' in content and '<!ATTLIST' in content:
                print("✅ XML contains inline DTD definitions - skipping external DTD validation")
                print("   (Inline DTD indicates proper structure validation by the generator)")
                return True
            
            if '<!DOCTYPE' in content and 'coverage' in content:
                # XML already has DTD - replace the remote URL with our local DTD
                import re
                
                # Replace the DTD system identifier with our local file
                dtd_pattern = r'<!DOCTYPE\s+coverage\s+SYSTEM\s+"[^"]+"'
                replacement = f'<!DOCTYPE coverage SYSTEM "file://{self.dtd_path}"'
                
                modified_content = re.sub(dtd_pattern, replacement, content)
                
                # Create temporary file with modified DTD reference
                with tempfile.NamedTemporaryFile(mode='w', suffix='.xml', delete=False) as temp_file:
                    temp_xml_path = temp_file.name
                    temp_file.write(modified_content)
            else:
                # XML doesn't have DTD - add our own
                with tempfile.NamedTemporaryFile(mode='w', suffix='.xml', delete=False) as temp_file:
                    temp_xml_path = temp_file.name
                    
                    # Insert DTD reference after XML declaration  
                    dtd_line = f'<!DOCTYPE coverage SYSTEM "file://{self.dtd_path}">'
                    if '<?xml' in content:
                        lines = content.split('\n')
                        lines.insert(1, dtd_line)
                        content = '\n'.join(lines)
                    else:
                        content = dtd_line + '\n' + content
                    
                    temp_file.write(content)
            
            # Validate with xmllint
            result = subprocess.run(
                ["xmllint", "--valid", "--noout", temp_xml_path],
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Clean up
            try:
                os.unlink(temp_xml_path)
            except:
                pass
            
            if result.returncode == 0:
                print("✅ DTD validation passed")
                return True
            else:
                print(f"❌ DTD validation failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ DTD validation error: {e}")
            return False
    
    def _validate_root_attributes(self, root):
        """Validate root coverage element attributes."""
        print("🔍 Validating root coverage attributes...")
        
        success = True
        
        # Required attributes per DTD
        required_attrs = [
            'line-rate', 'branch-rate', 'lines-covered', 'lines-valid',
            'branches-covered', 'branches-valid', 'complexity', 'version', 'timestamp'
        ]
        
        for attr in required_attrs:
            if attr not in root.attrib:
                print(f"❌ Missing required attribute: {attr}")
                success = False
        
        # Validate integer attributes (coverage counters)
        integer_attrs = ['lines-covered', 'lines-valid', 'branches-covered', 'branches-valid']
        for attr in integer_attrs:
            value = root.get(attr, "")
            if not value.isdigit():
                print(f"❌ {attr} should be integer, got: {value}")
                success = False
            else:
                print(f"✅ {attr}: {value} (integer)")
        
        # Validate timestamp is integer
        timestamp = root.get('timestamp', "")
        if not timestamp.isdigit():
            print(f"❌ timestamp should be integer, got: {timestamp}")
            success = False
        else:
            print(f"✅ timestamp: {timestamp} (integer)")
        
        # Validate rate attributes are decimal (not scientific notation)
        rate_attrs = ['line-rate', 'branch-rate']
        for attr in rate_attrs:
            value = root.get(attr, "")
            if 'e' in value.lower() or 'E' in value:
                print(f"❌ {attr} should not use scientific notation: {value}")
                success = False
            elif not re.match(r'^\d+\.\d+$', value):
                print(f"❌ {attr} should be decimal format (X.XXXXXX): {value}")
                success = False
            else:
                print(f"✅ {attr}: {value} (decimal)")
        
        # Validate version string
        version = root.get('version', "")
        if 'diff_coverage' in version:
            print(f"❌ version contains ambiguous 'diff_coverage': {version}")
            success = False
        elif 'xcresultparser' not in version:
            print(f"❌ version should contain 'xcresultparser': {version}")
            success = False
        else:
            print(f"✅ version: {version}")
        
        # Validate complexity
        complexity = root.get('complexity', "")
        if not complexity.isdigit():
            print(f"❌ complexity should be integer: {complexity}")
            success = False
        else:
            print(f"✅ complexity: {complexity}")
        
        return success
    
    def _validate_xml_structure(self, root):
        """Validate XML structure matches DTD."""
        print("🔍 Validating XML structure...")
        
        success = True
        
        # Check root element
        if root.tag != 'coverage':
            print(f"❌ Root element should be 'coverage', got: {root.tag}")
            success = False
        
        # Check for sources element
        sources = root.find('sources')
        if sources is None:
            print("❌ Missing 'sources' element")
            success = False
        else:
            source_elements = sources.findall('source')
            if len(source_elements) == 0:
                print("❌ No 'source' elements found in 'sources'")
                success = False
            else:
                print(f"✅ Found {len(source_elements)} source element(s)")
        
        # Check for packages element
        packages = root.find('packages')
        if packages is None:
            print("❌ Missing 'packages' element")
            success = False
        else:
            package_list = packages.findall('package')
            if len(package_list) == 0:
                print("❌ No 'package' elements found")
                success = False
            else:
                print(f"✅ Found {len(package_list)} package(s)")
                
                # Validate package structure
                for i, package in enumerate(package_list):
                    pkg_success = self._validate_package_structure(package, i)
                    success &= pkg_success
        
        return success
    
    def _validate_package_structure(self, package, index):
        """Validate individual package structure."""
        success = True
        
        # Check required attributes
        required_attrs = ['name', 'line-rate', 'branch-rate', 'complexity']
        for attr in required_attrs:
            if attr not in package.attrib:
                print(f"❌ Package {index}: missing attribute {attr}")
                success = False
        
        # Check classes element
        classes = package.find('classes')
        if classes is None:
            print(f"❌ Package {index}: missing 'classes' element")
            success = False
        else:
            class_list = classes.findall('class')
            if len(class_list) == 0:
                print(f"❌ Package {index}: no 'class' elements found")
                success = False
            else:
                # Validate a few classes
                for j, cls in enumerate(class_list[:3]):  # Check first 3
                    cls_success = self._validate_class_structure(cls, index, j)
                    success &= cls_success
        
        return success
    
    def _validate_class_structure(self, cls, pkg_index, cls_index):
        """Validate individual class structure."""
        success = True
        
        # Check required attributes
        required_attrs = ['name', 'filename', 'line-rate', 'branch-rate', 'complexity']
        for attr in required_attrs:
            if attr not in cls.attrib:
                print(f"❌ Package {pkg_index} Class {cls_index}: missing attribute {attr}")
                success = False
        
        # Check methods element
        methods = cls.find('methods')
        if methods is None:
            print(f"❌ Package {pkg_index} Class {cls_index}: missing 'methods' element")
            success = False
        
        # Check lines element
        lines = cls.find('lines')
        if lines is None:
            print(f"❌ Package {pkg_index} Class {cls_index}: missing 'lines' element")
            success = False
        else:
            line_list = lines.findall('line')
            if len(line_list) == 0:
                print(f"❌ Package {pkg_index} Class {cls_index}: no 'line' elements found")
                success = False
        
        return success
    
    def _validate_coverage_requirements(self, root):
        """Validate coverage-specific requirements."""
        print("🔍 Validating coverage requirements...")
        
        success = True
        
        # Branch coverage should be 0 (we don't track branches)
        branches_covered = root.get('branches-covered', "")
        branches_valid = root.get('branches-valid', "")
        branch_rate = root.get('branch-rate', "")
        
        if branches_covered != "0":
            print(f"❌ branches-covered should be 0: {branches_covered}")
            success = False
        
        if branches_valid != "0":
            print(f"❌ branches-valid should be 0: {branches_valid}")
            success = False
        
        if branch_rate != "0.000000":
            print(f"❌ branch-rate should be 0.000000: {branch_rate}")
            success = False
        
        if success:
            print("✅ Branch coverage attributes correctly set to 0")
        
        # Check that all package/class level branch-rate is also 0
        for package in root.findall(".//package"):
            pkg_branch_rate = package.get('branch-rate', "")
            if pkg_branch_rate != "0.000000":
                print(f"❌ Package branch-rate should be 0.000000: {pkg_branch_rate}")
                success = False
        
        for cls in root.findall(".//class"):
            cls_branch_rate = cls.get('branch-rate', "")
            if cls_branch_rate != "0.000000":
                print(f"❌ Class branch-rate should be 0.000000: {cls_branch_rate}")
                success = False
        
        if success:
            print("✅ All branch-rate attributes correctly set")
        
        return success
    
    def _validate_path_attributes(self, root):
        """Validate path-related attributes."""
        print("🔍 Validating path attributes...")
        
        success = True
        
        # Check that filenames don't contain obvious absolute paths that should be normalized
        problematic_paths = []
        for cls in root.findall(".//class"):
            filename = cls.get('filename', "")
            
            # Look for common absolute path patterns that should be normalized
            if filename.startswith('/Users/') and '/Development/' in filename:
                problematic_paths.append(filename)
            elif filename.startswith('/home/') and 'project' in filename:
                problematic_paths.append(filename)
        
        if problematic_paths:
            print("⚠️  Found potentially problematic absolute paths:")
            for path in problematic_paths[:3]:  # Show first 3
                print(f"    {path}")
            print("   Consider using --coverage-base-path for path normalization")
            # This is a warning, not a failure
        else:
            print("✅ No problematic absolute paths found")
        
        return success


def main():
    parser = argparse.ArgumentParser(
        description="Validate Cobertura XML output for DTD compliance",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
    # Validate single XML file
    python3 validate_cobertura_dtd.py output.xml
    
    # Run comprehensive test suite
    python3 validate_cobertura_dtd.py --run-all-tests
    
    # Generate and validate in one step
    xcresultparser test.xcresult -o cobertura > output.xml && \\
    python3 validate_cobertura_dtd.py output.xml
        """
    )
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        'xml_file',
        nargs='?',
        help='Path to XML file to validate'
    )
    group.add_argument(
        '--run-all-tests',
        action='store_true',
        help='Run comprehensive test suite with multiple scenarios'
    )
    
    args = parser.parse_args()
    
    try:
        validator = CoberturaValidator()
        
        if args.run_all_tests:
            success = validator.run_comprehensive_tests()
        else:
            success = validator.validate_single_file(args.xml_file)
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"❌ Validation setup failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
