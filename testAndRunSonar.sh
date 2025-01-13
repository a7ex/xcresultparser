#!/bin/sh

usage()
{
	echo ""
	echo "NAME: $0"
    echo ""
    echo "SYNOPSIS:"
    echo "$0 [-t <access token>]"
	echo ""
    echo "DESCRIPTION:"
	echo " -- Run the tests and send the results to sonar."
 	echo "    Here we define the project specific variables, which are required for the runSonar.sh script."
 	echo "    Note that one single value, which is required is not hard coded into this file for obvious reasons:"
 	echo "    The sonar API key needs to be sent to this script as parameter."
	echo ""
    echo "  The options are as follows:"
	echo "    -t | --sonarqube-login-token  Access token to connect to the sonar server."
    echo "    -h | --help              		This help"
	echo ""
}

## Default values for this app, so I can invoke this script with only one parameter for the token, which shall not be stored in the public repository.
sonarqube_host_url="https://sonarcloud.io"
sonarqube_project_key="a7ex_xcresultparser"
sonarqube_project_name="xcresultparser"
sonarqube_organization="a7ex"
skip_build=false

while [ "$1" != "" ]; do
    case $1 in
        -t | --sonarqube-login-token )  shift
                            			sonarqube_login_token="$1"
                        				;;
        -s | --skip-build )  			skip_build=true
                        				;;
        -h | --help )       			usage
                        				exit
                            			;;
    esac
    shift
done

if [ -z "$sonarqube_login_token" ]
then
	echo "Error: Please provide the api key (access token) for the sonar account!"
	exit 1
fi

# build the project for M1 and Intel:

path_to_xcresults="$(pwd)/product/xcresultparser.xcresult"
if [ -d "$path_to_xcresults" ]; then
	if [ "$skip_build" != true ]; then
		rm -r "$path_to_xcresults"
	fi
fi

if [ ! -d "$path_to_xcresults" ]; then
	/usr/bin/xcrun xcodebuild clean test -workspace .swiftpm/xcode/package.xcworkspace -scheme xcresultparser -destination "platform=macOS" -resultBundlePath "$path_to_xcresults"
fi

app_project_version=$(grep 'marketingVersion =' CommandlineTool/main.swift | cut -d "=" -f2 | xargs)

if [ -d "$path_to_xcresults" ]
then
	sh runSonar.sh \
	-s $sonarqube_host_url \
	-p $sonarqube_login_token \
	-k $sonarqube_project_key \
	-n "$sonarqube_project_name" \
 	-o "$sonarqube_organization" \
	-v "$app_project_version" \
	-r "$path_to_xcresults"
fi
