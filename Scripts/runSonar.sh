#!/bin/sh

usage()
{
	echo ""
	echo "NAME: $0"
    echo ""
    echo "SYNOPSIS:"
    echo "$0 [-t <teamId>] [-n <productName>] [-p profileName]"
	echo ""
    echo "DESCRIPTION:"
	echo " -- Script to create a SonarQube run and publish results"
	echo ""
    echo "  The options are as follows:"
	echo "    -s | --sonarqube-host          Host of the sonarqube instance."
    echo "    -p | --sonarqube-login-token   The credentials to access the sonarqube instance."
	echo "    -k | --sonarqube-project-key   The key which identifies the project in sonar."
	echo "    -n | --sonarqube-project-name  The key of the project in sonar."
	echo "    -v | --app-version             The version of the project."
	echo "    -r | --path-to-xcresult        The xcresult bundle with data about tests and coverage."
    echo "    -h | --help                    This help."
	echo ""
}

sourcesPath=Sources
testsPath=Tests

while [ "$1" != "" ]; do
    case $1 in
        -s | --sonarqube-host )     	shift
        								sonarqube_host_url="$1"
                        				;;
        -p | --sonarqube-login-token )  shift
        								sonarqube_login_token="$1"
                        				;;
        -k | --sonarqube-project-key )  shift
        								sonarqube_project_key="$1"
                        				;;
        -n | --sonarqube-project-name ) shift
        								sonarqube_project_name="$1"
                        				;;
        -o | --sonarqube-organization ) shift
        								sonarqube_organization="$1"
                        				;;
        -v | --app-version )     		shift
        								app_project_version="$1"
                        				;;
        -r | --path-to-xcresult )		shift
                            			xcresultPath="$1"
                        				;;
        -h | --help )       			usage
                        				exit
                            			;;
    esac
    shift
done

root_path=`git rev-parse --show-toplevel`
if [ ! -z "$root_path" ]
then
    cd "$root_path"
else
    root_path="$(pwd)"
fi


sonarPath=$(which sonar-scanner)
if [ ! -x "$sonarPath" ]
then
    sonarPath="/opt/homebrew/bin/sonar-scanner"
    if [ ! -x "$sonarPath" ]
    then
		brewPath=$(which brew)
		if [ ! -x "$brewPath" ]
		then
			brewPath="/usr/local/bin/brew"
			if [ ! -x "$brewPath" ]
			then
				echo -e "Need brew to install the 'sonar-scanner' binary"
				exit 1
			fi
		fi
        echo "Installing 'sonar-scanner' binary"
        "$brewPath" update && "$brewPath" install sonar-scanner
        sonarPath=$(which sonar-scanner)
    fi
fi

if [ ! -x "$sonarPath" ]
then
    echo -e "The 'sonar-scanner' binary is not executble at: $sonarPath"
    exit 1
fi

# We can either provide 'xcresultparser' as tool in the project's repository,
resultparserPath=xcresultparser
if [ ! -x "$resultparserPath" ]
then
	# ...or we have installed it for all jobs on the agent:
	resultparserPath=$(which xcresultparser)
    if [ ! -x "$resultparserPath" ]
    then
        resultparserPath="/opt/homebrew/bin/xcresultparser"
    fi
fi

echo "-------------------\nStarting sonar scan for app_project_version (Build): $app_project_version\n-------------------"

if [ ! -z "$xcresultPath" -a -d "$xcresultPath" -a -x "$resultparserPath" ]
then
    echo "Convert xcresult to sonarqube compatible coverage xml. Path to xcresult file: $xcresultPath"
       "$resultparserPath" -cq -o xml "$xcresultPath" > sonarqube-coverage.xml

    echo "Convert xcresult to sonarqube compatible Junit xml."
    "$resultparserPath" -q -o xml -p "$root_path" "$xcresultPath" > sonarqube-testresults.xml
fi

if [ -s sonarqube-coverage.xml ]
then
    echo "Run sonar scanner with coverage now for (sonarqube_project_name) ${sonarqube_project_name} with $sonarPath"
#    "$sonarPath" -X // with DEBUG messages
    "$sonarPath" \
        -Dsonar.host.url="${sonarqube_host_url}" \
        -Dsonar.token="${sonarqube_login_token}" \
        -Dsonar.projectKey="${sonarqube_project_key}" \
        -Dsonar.projectName="${sonarqube_project_name}" \
        -Dsonar.projectVersion="${app_project_version}" \
        -Dsonar.organization="${sonarqube_organization}" \
        -Dsonar.sources="$(pwd)/${sourcesPath}" \
        -Dsonar.exclusions=**/*.html \
        -Dsonar.coverageReportPaths="sonarqube-coverage.xml" \
        -Dsonar.testExecutionReportPaths="sonarqube-testresults.xml" \
        -Dsonar.tests="${testsPath}" \
        -Dsonar.c.file.suffixes=- \
        -Dsonar.cpp.file.suffixes=- \
        -Dsonar.objc.file.suffixes=-
else
    echo "Run sonar scanner without coverage for (sonarqube_project_name) ${sonarqube_project_name} with $sonarPath"
	"$sonarPath" \
	  -Dsonar.host.url="${sonarqube_host_url}" \
	  -Dsonar.token="${sonarqube_login_token}" \
	  -Dsonar.projectKey="${sonarqube_project_key}" \
	  -Dsonar.projectName="${sonarqube_project_name}" \
	  -Dsonar.projectVersion="${app_project_version}" \
	  -Dsonar.organization="${sonarqube_organization}" \
	  -Dsonar.sources="$sourcesPath" \
      -Dsonar.exclusions=**/*.html
fi
if [ $? -ne 0 ]
then
    echo "-------------------\nSonar scan completed with error!\n-------------------"
    exit 1
else
    echo "-------------------\nSonar scan completed!\n-------------------"
    exit 0
fi
