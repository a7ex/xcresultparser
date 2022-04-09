# xcresultparser

## Overview
Parse the binary xcresult bundle from Xcode builds and test runs.

Interpret binary .xcresult files and print summary in different formats:
- txt
- colored command line output
- xml
- html

In case of 'xml' JUnit format for test results and generic format (Sonarqube) for coverage data is used.

You can also specify the name of the project root. Paths and urls are then relative to the specified directory. (used for urls in xml output)

This tool can read test result data and code coverage data from an .xcarchive using the developer tools included in `Xcode 11`. Namely here: xcresulttool and xccov to get json data from .xcresult bundles.

Parsing the JSON is done using the great [XCResultKit](https://github.com/davidahouse/XCResultKit) package.

## Converting code coverage data
Unfortunately converting to the coverage xml format suited for e.g. sonarqube is a tedious task.
It requires us to invoke the xccov binary for each single file in the project.

First we get a list of source files with coverage data from the archive, using xccov --file-list
and then we need to invoke xccov for each single file. That takes a considerable amount of time.
So at least we can spread it over different threads, so that it executes in parallel and is overall faster.

Until now we used [xccov-to-sonarqube-generic.sh]( https://github.com/SonarSource/sonar-scanning-examples/blob/master/swift-coverage/swift-coverage-example/xccov-to-sonarqube-generic.sh)
which does the same job, just in a shell script. It has the same problem
and since it can not spawn it to different threads, it takes about 5x the time.

## How to get it
### Using homebrew
```
brew tap a7ex/homebrew-formulae
brew install xcresultparser
```
### Download binary
- Download `xcresultparser.zip` binary from the latest [release](https://github.com/a7ex/xcresultparser/releases/latest)
- Copy `xcresultparser` to your desktop
- Open a Terminal window and run this command to give the app permission to execute:

```
chmod +x ~/Desktop/xcresultparser
```
**IMPORTANT NOTE:** This binary is not notarized/certified by Apple yet. So you must go to SystemSettings:Security and explicitely allow the app to execute, after the first attempt to launch it in the terminal, in case you want to take the risk. I will try to notarize it asap and get rid of this 'Important note'.


Or build the tool yourself:

- Clone the repository / Download the source code
- Run `swift build -c release` to build `xcresultparser` executable
- Run `open .build/release` to open directory containing the executable file in Finder
- Drag `xcresultparser` executable from the Finder window to your desktop

## How to install it
### Using homebrew
```
brew tap a7ex/homebrew-formulae
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

OVERVIEW: Interpret binary .xcresult files and print summary in different formats: txt, xml, html or colored cli output.

USAGE: xcresultparser [--output-format <output-format>] [--project-root <project-root>] [--coverage-targets <coverage-targets> ...] [--coverage ...] [--no-test-result ...] [--quiet ...] <xcresult-file>

ARGUMENTS:
  <xcresult-file>         The path to the .xcresult file.

OPTIONS:
  -o, --output-format <output-format>
                          The output format. It can be either 'txt', 'cli', 'html' or 'xml'. In case of 'xml' JUnit format for test results and generic format
                          (Sonarqube) for coverage data is used.
  -p, --project-root <project-root>
                          The name of the project root. If present paths and urls are relative to the specified directory.
  -t, --coverage-targets <coverage-targets>
                          Specify which targets to calculate coverage from
  -c, --coverage          Whether to print coverage data.
  -n, --no-test-result    Whether to print test results.
  -q, --quiet             Quiet. Don't print status output.
  -h, --help              Show help information.
```
Now that a copy of `xcresultparser` is in your search path, delete it from your desktop.

You're ready to go! 🎉

## How to use it
The tool doesn't create any file. It justs outputs its results to standard out. It is up to you to write the output to a file, using redirection.
For example, if you want to write the text output into a file named `output.txt` on your desktop:
```
./xcresultparser -o txt test.xcresult > ~/Desktop/output.txt
```
However, if all you need is to output the contents of the xcresult bundle to the terminal:
```
./xcresultparser -o cli test.xcresult
```

## Examples
### Colored CLI output
Print the test results in color to the command line:
```
./xcresultparser -o cli test.xcresult
```
![Colored command line output](images/cliColor.png)

### HTML output
Create a single html file with test data
```
./xcresultparser -o html test.xcresult > testResult.html
```
![Interactive single page HTML file](images/testResultHTML.png)

### Junit output
Create an xml file in JUnit format:
```
./xcresultparser -o xml test.xcresult > junit.xml
```

### Sonarqube output
Create an xml file in generic code coverage xml format:
```
./xcresultparser -c -o xml test.xcresult > sonar.xml
```
About paths for the sonarqube scanner. The tools to get the data from the xcresult archive yield absolute path names.
So you must provide an absolute pathname to the *sonar.sources* paramater of the *sonar-scanner* CLI tool and it must of course match the directory, where *xcodebuild* ran the tests and created the *.xcresult* archive.

In cases where the xcresult archive is not created on the same machine and the paths used for *sonar-scanner* differ, the pathnames need to be adjusted.
In such a case you can use a relative path for the *sonar.sources* paramater of the *sonar-scanner* CLI tool and convert the output of xcresultparser to also return relative path names.
The parameter -p or --project-root takes a string in order to find and delete the beginning of the pathnames, so they are relative. The way this is done is let's say pretty naiv… The string provided with --project-root is searched in the absolute path and, if found, the path is chopped up to and including the provided string.
**Example**:
./xcresultparser -c -o xml --project-root "work/myApp/" test.xcresult > sonar.xml
Example path in xcresult: */Users/alex/work/myApp/Sources/myApp/SomeClass.swift* will be converted to: *Sources/myApp/SomeClass.swift*
Now make sure you call *sonar-scanner* from within the root of your project and use the relative path "Sources" as parameter for *sonar.sources*.
