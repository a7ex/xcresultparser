# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version 1.1 - 2022-04-03
### CHANGES:
(Kind of) Fixed the file paths in test results xml for sonarqube.
Unfortunately I didn't find the file paths for the tests in the xcresult archive.
Only the classnames of the test classes are exposed. So I use `grep` to find the
file in the directory provided with the '-p' parameter. That will only work on the machine
where the .xcresult file was created, because only there the files exist, which can be found by `grep`. 