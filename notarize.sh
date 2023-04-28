# First (if not already done) create a profile and store it in the keychain for later use with notary tool
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
	echo " -- Compile the app for M1 and Intel (fat) and notorize the resulting binary with Apple"
	echo ""
    echo "  The options are as follows:"
	echo "    -t | --teamId             Your Apple Developer Team Id (go to developer.apple.com, log in and scrol down.)"
    echo "    -n | --productName        The name of the product, so it can be found in the .build folder."
	echo "    -p | --profileName        The name of the credentials profile, which is stored in the keychain."
	echo "                              To create such a profile use: `xcrun notarytool store-credentials`"
    echo "    -h | --help               This help"
	echo ""
}

## Default values for this app, so I can invoke this script without parameters
productName="xcresultparser"

while [ "$1" != "" ]; do
    case $1 in
        -t | --teamId )     	shift
                            	teamId="$1"
                        		;;
        -n | --productName )	shift
                            	productName="$1"
                        		;;
        -p | --profileName ) 	shift
                            	productName="$1"
                        		;;
        -h | --help )       	usage
                        		exit
                            	;;
    esac
    shift
done

if [ -z "$teamId" ]
then
	echo "Please provide the TeamID of your Apple Developer Account"
	exit 1
fi

if [ -z "$profileName" ]
then
	echo "Please provide a profile name of the profile in your keychain, which was created using `notarytool store-credentials`"
	exit 1
fi

# build the project for M1 and Intel:
swift build -c release --arch arm64 --arch x86_64

# move the result from the .build folder to the product folder
cp ".build/apple/Products/Release/$productName" "product/$productName"

# Now codesign the app with hardening (-o)
codesign --sign "$teamId" -o runtime "product/$productName"

# Create zip archive
zip -r "product/${productName}.zip" "product/$productName"

# upload to notary
xcrun notarytool submit "product/${productName}.zip" -p "$keychainProfileName"

# ------------------------- Sample Output
# Conducting pre-submission checks for xcresultparser.zip and initiating connection to the Apple notary service...
# Submission ID received
#   id: 4a078fbf-6069-469f-8158-6de5c8e03315
# Upload progress: 100,00 % (1,39 MB of 1,39 MB)
# Successfully uploaded file
#   id: 4a078fbf-6069-469f-8158-6de5c8e03315
#   path: /Users/alex/Work/__OwnProjects/myGithub/xcresultparser/product/xcresultparser.zip
# -------------------------


#####################################################################################
################# Later call 'info' or 'log' to verify the result
# info:
# xcrun notarytool info <submission id from previous step> -p FarbflashAppleDevAccount

# ------------------------- Sample Output
# Successfully received submission info
#   createdDate: 2023-04-28T05:42:55.955Z
#   id: 4a078fbf-6069-469f-8158-6de5c8e03315
#   name: xcresultparser.zip
#   status: Accepted
# -------------------------

# log:
# xcrun notarytool log <submission id from previous step> -p FarbflashAppleDevAccount

# ------------------------- Sample Output
# {
#   "logFormatVersion": 1,
#   "jobId": "4a078fbf-6069-469f-8158-6de5c8e03315",
#   "status": "Accepted",
#   "statusSummary": "Ready for distribution",
#   "statusCode": 0,
#   "archiveFilename": "xcresultparser.zip",
#   "uploadDate": "2023-04-28T05:42:58.669Z",
#   "sha256": "b1d5cfe49f50c791c3f4b98a9c59862b18d6373f27388d6172ce4547e0b3402a",
#   "ticketContents": [
#     {
#       "path": "xcresultparser.zip/xcresultparser",
#       "digestAlgorithm": "SHA-256",
#       "cdhash": "53c2792da2debf2224eb22ee77da8a35ad9dac60",
#       "arch": "x86_64"
#     },
#     {
#       "path": "xcresultparser.zip/xcresultparser",
#       "digestAlgorithm": "SHA-256",
#       "cdhash": "ae0727572cac10aba7e38ff8a901f211a08f276d",
#       "arch": "arm64"
#     }
#   ],
#   "issues": null
# }
# -------------------------