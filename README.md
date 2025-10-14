# xcresultparser

## Overview
Parse the binary xcresult bundle from Xcode builds and test runs.

Interpret binary .xcresult files and print summary in different formats:
- txt
- colored command line output
- xml
- junit
- cobertura
- html
- markdown
- warnings
- errors

In case of 'xml' JUnit format for test results and generic format (Sonarqube) for coverage data is used.

You can also specify the name of the project root. Paths and urls are then relative to the specified directory. (used for urls in xml output)

This tool can read test result data and code coverage data from an .xcarchive using the developer tools included in `Xcode 13`. Namely here: xcresulttool and xccov to get json data from .xcresult bundles.

Parsing the JSON is done using the great [XCResultKit](https://github.com/davidahouse/XCResultKit) package.

<details>
  <summary>More on converting code coverage data</summary>
  
~~Unfortunately converting to the coverage xml format suited for e.g. sonarqube is a tedious task.
It requires us to invoke the xccov binary for each single file in the project.~~

~~First we get a list of source files with coverage data from the archive, using xccov --file-list
and then we need to invoke xccov for each single file. That takes a considerable amount of time.
So at least we can spread it over different threads, so that it executes in parallel and is overall faster.~~

~~Until now we used [xccov-to-sonarqube-generic.sh]( https://github.com/SonarSource/sonar-scanning-examples/blob/master/swift-coverage/swift-coverage-example/xccov-to-sonarqube-generic.sh)
which does the same job, just in a shell script. It has the same problem
and since it can not spawn it to different threads, it takes about 5x the time.~~

It used to be like described above up until Xcode 13. Xcode 13 brought a new version of the xccov commandline tool, which now can output the entire coverage data at once. No more tedious task of calling into xccov for each single swift file!
Therefore the shell script [xccov-to-sonarqube-generic.sh](https://github.com/SonarSource/sonar-scanning-examples/blob/master/swift-coverage/swift-coverage-example/xccov-to-sonarqube-generic.sh) provided by sonar does the job in the same time as xcresultparser. That renders the initial purpose of this tool useless. However, xcresultparser meanwhile can do a few more tricks, than only converting coverage data from a xcresult bundle to xml suited for sonarqube.

It my still be useful for you, if you want to just display the contents of the xcresult bundle (the tests) in a terminal, as html or as markdown for your build chain.

It can also be used for cobertura, thanks to the collaboration of Thibault Wittemberg and maxwell-legrand.

Furthermore it can extract testdata from the xcresult bundle in junit format, also suited for sonarqube.
</details>

## How to get it
### Using homebrew
```
brew install xcresultparser
```
### Download binary
- Download `xcresultparser.zip` binary from the latest [release](https://github.com/a7ex/xcresultparser/releases/latest)
- Copy `xcresultparser` to your desktop
- Open a Terminal window and run this command to give the app permission to execute:

```
chmod +x ~/Desktop/xcresultparser
```

Or build the tool yourself:

- Clone the repository / Download the source code
- Run `swift build -c release` to build `xcresultparser` executable
- Run `open .build/release` to open directory containing the executable file in Finder
- Drag `xcresultparser` executable from the Finder window to your desktop

## How to install it
### Using homebrew
```
brew install xcresultparser
```
### Downloaded binary
Assuming that the `xcresultparser` app is on your desktop…

Open a Terminal window and run this command:
```
cp ~/Desktop/xcresultparser /usr/local/bin/
```
Verify `xcresultparser` is in your search path by running this in Terminal:
```
xcresultparser
```
You should see the tool respond like this:
```
Error: Missing expected argument '<xcresult-file>'

OVERVIEW: xcresultparser 1.9.3
Interpret binary .xcresult files and print summary in different formats: txt,
xml, html or colored cli output.

USAGE: xcresultparser [<options>] [<xcresult-file>]

ARGUMENTS:
  <xcresult-file>         The path to the .xcresult file.

OPTIONS:
  --coverage-report-format <coverage-report-format>
                          The coverage report format. The Default is 'methods',
                          It can either be 'totals', 'targets', 'classes' or
                          'methods'
  -o, --output-format <output-format>
                          The output format. It can be either 'txt', 'cli',
                          'html', 'md', 'xml', 'junit', 'cobertura',
                          'warnings', 'errors' and 'warnings-and-errors'. In
                          case of 'xml' sonar generic format for test results
                          and generic format (Sonarqube) for coverage data is
                          used. In the case of 'cobertura', --coverage is
                          implied.
  -p, --project-root <project-root>
                          The name of the project root. If present paths and
                          urls are relative to the specified directory.
  -t, --coverage-targets <coverage-targets>
                          Specify which targets to calculate coverage from. You
                          can use more than one -t option to specify a list of
                          targets.
  -e, --excluded-path <excluded-path>
                          Specify which path names to exclude. You can use more
                          than one -e option to specify a list of path patterns
                          to exclude. This option only has effect, if the
                          format is either 'cobertura' or 'xml' with the
                          --coverage (-c) option for a code coverage report or
                          if the format is one of 'warnings', 'errors' or
                          'warnings-and-errors'.
  -s, --summary-fields <summary-fields>
                          The fields in the summary. Default is all:
                          errors|warnings|analyzerWarnings|tests|failed|skipped
  -c, --coverage          Whether to print coverage data.
  -x, --exclude-coverage-not-in-project
                          Omit elements with file pathes, which do not contain
                          'projectRoot'.
  -n, --no-test-result    Whether to print test results.
  -f, --failed-tests-only Whether to only print failed tests.
  -q, --quiet             Quiet. Don't print status output.
  -i, --target-info       Just print the targets contained in the xcresult.
  -v, --version           Show version number.
  -h, --help              Show help information.
```
Now that a copy of `xcresultparser` is in your search path, delete it from your desktop.

You're ready to go! 🎉

## How to use it
The tool doesn't create any file. It justs outputs its results to standard out. It is up to you to write the output to a file, using redirection.
For example, if you want to write the text output into a file named `output.txt` on your desktop:
```
xcresultparser -o txt test.xcresult > ~/Desktop/output.txt
```
However, if all you need is to output the contents of the xcresult bundle to the terminal:
```
xcresultparser -o cli test.xcresult
```

You can also merge two xcresult files with:
```
xcrun xcresulttool merge Result1.xcresult Result2.xcresult --output-path=Result_merged.xcresult
```

With xcresultparser >= 1.5.2 you can now call:
xcresultparser Result_merged.xcresult --output-format=junit

It iterates through all available test actions
It creates a test suite for each test action
It sets the overall test time of the testsuites to the sum of all test suite times.

## Examples
### Colored CLI output
Print the test results in color to the command line:
```
xcresultparser -o cli test.xcresult
```
![Colored command line output](images/cliColor.png)

### HTML output
Create a single html file with test data
```
xcresultparser -o html test.xcresult > testResult.html
```
![Interactive single page HTML file](images/testResultHTML.png)

### Junit output
Create an xml file in JUnit format:
```
xcresultparser -o junit test.xcresult > junit.xml
```

### Sonarqube output
Create an xml file in generic test exectuion xml format:
```
xcresultparser -o xml test.xcresult > sonarTestExecution.xml
```

Create an xml file in generic code coverage xml format for all targets:
```
xcresultparser -c -o xml test.xcresult > sonarCoverage.xml
```

Create an xml file in generic code coverage xml format, but only for two of the targets "foo" and "baz":
```
xcresultparser -c -o xml test.xcresult -t foo -t baz > sonarCoverage.xml
```

### Cobertura XML output
Create xml file in [Cobertura](https://cobertura.github.io/cobertura/) format:
```
xcresultparser -o cobertura test.xcresult > cobertura.xml
```

Note that some data in this file is currently fake as of this time of writing, but should have accurate line coverage information. It should be good enough for importing into tools like [GitLab coverage visualizer](https://docs.gitlab.com/ee/ci/testing/test_coverage_visualization.html).

It may be desirable to also pass --project-root if you wish to alter the filenames and sources in the Cobertura report (see note below) - this is required for GitLab compatbility.

### Markdown output
Simple markdown formatting for test results. (We use it for display in a Teams Webhook)
```
xcresultparser -o md test.xcresult > teamsWebhook.txt
```

### Code Climate output
JSON output for Code Climate checks
```
xcresultparser -o warnings test.xcresult > climate.json
```

### Error output
JSON output describing errors
```
xcresultparser -o errors test.xcresult > errors.json
```

#### About paths for the sonarqube scanner
The tools to get the data from the xcresult archive yield absolute path names.
So you must provide an absolute pathname to the *sonar.sources* paramater of the *sonar-scanner* CLI tool and it must of course match the directory, where *xcodebuild* ran the tests and created the *.xcresult* archive.

If you want to use the test results for sonarqube, there is another twist: the .xcresult bundle only lists the test by testclass, but not by file. However the sonarqube CLI tool expects the file paths of the tests. In this case you must provide a --project-root to *xcresultparser*. Only then *xcresultparser* can convert the classnames to file names, by *egrep*-ing for `^(?:public )?(?:final )?(?:public )?(?:(class|\@implementation) )\w+`. If such a file is found in the directory provided in *--project-root*, then the file path can be detrmined and the *sonar-scanner* happily can scan the files for tests. The pattern matches all swift and objective-c classes.

Since searching all files in `project-root` takes some time, an index path names for class names is created beforehand and used as lookup table.

The following egrep expression is used to create the lookup table for the filenames of classes:
```
egrep -rio --include "*.swift" --include "*.m" "^(?:public )?(?:final )?(?:public )?(?:(class|\@implementation) )\w+" $project-root
```

In cases where the xcresult archive is not created on the same machine and the paths used for *sonar-scanner* differ, the pathnames need to be adjusted.
In such a case you can use a relative path for the *sonar.sources* paramater of the *sonar-scanner* CLI tool and convert the output of xcresultparser to also return relative path names.
The parameter -p or --project-root takes a string in order to find and delete the beginning of the pathnames, so they are relative. The way this is done is let's say pretty naiv… The string provided with --project-root is searched in the absolute path and, if found, the path is chopped up to and including the provided string.
**Example**:
./xcresultparser -c -o xml --project-root "work/myApp/" test.xcresult > sonar.xml
Example path in xcresult: */Users/alex/work/myApp/Sources/myApp/SomeClass.swift* will be converted to: *Sources/myApp/SomeClass.swift*
Now make sure you call *sonar-scanner* from within the root of your project and use the relative path "Sources" as parameter for *sonar.sources*.
