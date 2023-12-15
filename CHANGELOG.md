# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version 1.5.2 - 2023-12-15
### CHANGES:
Add support for multiple testsuites in junit xml

## Version 1.5.1 - 2023-12-01
### CHANGES:
Adds support for Skipped and Expected Failure test statuses

## Version 1.5.0 - 2023-10-16
### CHANGES:
- Merged Pull Request to allow multiple run destinations to be processed correctly (Credits to Alex Deem https://github.com/alexdeem)

## Version 1.4.2 - 2023-05-25
### CHANGES:
- updated dependencies to their latest versions
- Added static local coverage-04.dtd file for cobertura coverage converter, for the case when http://cobertura.sourceforge.net/xml/coverage-04.dtd is not reachable
- fixed warnings for printing optionals

## Version 1.3.1 - 2023-02-12
### CHANGES:
Fixed bug where coverage would gather coverage for duplicate files

## Version 1.3 - 2023-02-11
### CHANGES:
Added support for the targets filter for the coverage functions as well
Added new method to just list all target names contained in the xcresult archive

## Version 1.2.2 - 2023-01-08
### CHANGES:
Fixes the junit output formatter, set cobertura timestamp to test execution time and improves the entire test suite.

## Version 1.2.1 - 2023-01-03
### CHANGES:
Make output test report format for xml output selectable.

## Version 1.2.0 - 2022-12-15
### CHANGES:
Added output format for coverage data: cobertura XML (this format is the only one supported by GitLab coverage visualizer). (Credits go to Eliot Lash)

## Version 1.1.6 - 2022-10-06
### CHANGES:
Fixed crash in coverage XML when output is concurrently modified. (Credits go to Björn Dahlgren)

## Version 1.1.5 - 2022-06-05
### CHANGES:
escaped quotes in markdown
changed formatting in markdown to better suit the needs for teams web hook

## Version 1.1.4 - 2022-06-01
### CHANGES:
Added simple markdown output (first implemented for use in Teams Webhook message).

## Version 1.1.3 - 2022-04-04
### CHANGES:
Changed format of test duration for sonar now from double to long

## Version 1.1.2 - 2022-04-04
### CHANGES:
Fixed format of test duration for sonar

## Version 1.1.1 - 2022-04-03
### CHANGES:
- added -v switch to output version of the tool

## Version 1.1.0 - 2022-04-03
### CHANGES:
(Kind of) Fixed the file paths in test results xml for sonarqube.
Unfortunately I didn't find the file paths for the tests in the xcresult archive.
Only the classnames of the test classes are exposed. So I use `grep` to find the
file in the directory provided with the '-p' parameter. That will only work on the machine
where the .xcresult file was created, because only there the files exist, which can be found by `grep`. 
