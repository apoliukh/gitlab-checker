#!/bin/bash

set -o errexit

SUBJECT="GitLab Checker"
START_TIME=$SECONDS

white=$(tput bold)
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 6)

bg_red=$(tput setab 1)
bg_green=$(tput setab 2)
bg_yellow=$(tput setab 3)
normal=$(tput sgr0)

OK="${green}OK${normal}"
FAIL="${red}FAIL${normal}"

function _echo
{
    if [[ -z "$2" ]]
    then
        printf '%s' "$1"
    else
        printf '%s\n' "$1"
    fi
}

function _echoTest
{
    _echo "${yellow}$1 test${normal} ... "
}

function _ok
{
    _echo $OK;
}

function _fail
{
    _echo $FAIL; exit 1;
}

function _startTime
{
    start=$(date +'%s')
}

function _endTime
{
    _echo " ($(($(date +'%s') - $start))s)" 1
}

function _logo
{
    echo "${blue}  _   _                      ${yellow}_${normal}"
    echo "${blue} | | | |_   _ _ __   ___ _ _${yellow}(_)${normal}${blue} __ _ ${normal}"
    echo "${blue} | |_| | | | | '_ \ / _ \ '_${yellow}| |${normal}${blue}/ _' |${normal}"
    echo "${blue} |  _  | |_| | |_) |  __/ | ${yellow}| |${normal}${blue} (_| |${normal}"
    echo "${blue} |_| |_|\__, | .__/ \___|_| ${yellow}|_|${normal}${blue}\__,_|${normal}"
    echo "${blue}        |___/|_|       ${normal}${white}$SUBJECT${normal}"
    echo ""
}

function usage
{
    
    cat <<EOF
usage:
$(basename $0) [ -n | -i | -t | -h ]

-n <ip|hostname>
Name of the host or IP address.

-i <number>
Project ID. Gitlab path: 
"Project" -> "General Settings" -> "Expand: General project settings"

-t <string>
Personal access tokens. Gitlab path: 
"User Settings" -> "Access Tokens"

-h
Prints this help.

EOF
    exit $1
}

function _curl
{
    _curl_with_error_code "$@" | sed '$d'
}

function _curl_with_error_code
{
    local curl_error_code http_code
    exec 17>&1
    http_code=$(curl --write-out '\n%{http_code}\n' "$@" | tee /dev/fd/17 | tail -n 1)
    curl_error_code=$?
    exec 17>&-

    if [ $curl_error_code -ne 0 ]; then
        return $curl_error_code
    fi

    if [ $http_code -ge 400 ] && [ $http_code -lt 600 ]; then
        echo "$FAIL (HTTP $http_code)" # >&2
        return 127
    fi
}

function _checkUpdate
{
    if [[ $1 != "null" ]]; then
        VERSION=$1
        VERSIONB64=`echo "{\"version\":\"$VERSION\"}" | base64`
        URL="https://version.gitlab.com/check.svg?gitlab_info=${VERSIONB64}"
        RESULT=`wget -q -O- --header="Referer: https://google.com" ${URL} | grep -oPm1 "(?<=\">)(.*)<\/text>" | grep -oP ".+?(?=<\/text>)"`

        if [[ $RESULT == "update asap" ]]; then
            echo "${bg_red}${white} ${RESULT} ${normal}"
        elif [[ $RESULT == "update available" ]]; then
            echo "${bg_yellow}${white} ${RESULT} ${normal}"
        else
            echo "${bg_green}${white} ${RESULT} ${normal}"
        fi
    else
        echo ""
    fi
}

OPTERR=0
GITLAB_API=""
TOKEN=""
PROJECT_ID=""
while getopts ":n:i:t:h" options
do
    case $options in
        n)
            GITLAB_API=$OPTARG"/api/v4"
            ;;
        i)
            PROJECT_ID=$OPTARG
            ;;
        t)
            TOKEN=$OPTARG
            ;;
        h|*) 
            _logo
            usage 0
            ;;
    esac
done
shift $(($OPTIND - 1))

function _errorMessage
{
    _echo "${red}Error${normal}" 1
    _echo "${red}$1${normal}" 1
    _echo "" 1    
    _echo "usage:" 1
    _echo "$(basename $0) -h" 1
    exit 1
}

if [[ -z $GITLAB_API ]]; then
    _errorMessage "Hostname not set."    
fi

if [[ -z $PROJECT_ID ]]; then
    _errorMessage "Project ID not set."    
fi

if [[ -z $TOKEN ]]; then
    _errorMessage "Token not set."
fi

function main
{
    _logo

    # init / clean
    tmp_dir="tmp_dir/"
    rm -rf $tmp_dir

    _echoTest "API"
    _startTime
    gitlab_version=$(mktemp)
    _curl --silent "$GITLAB_API/version/?private_token=$TOKEN" > $gitlab_version; td=`cat $gitlab_version`; if [[ -z $td ]]; then _fail; else _ok; fi;
    _endTime
    version=`cat $gitlab_version | jq '.version' | tr -d '"'`
    _echo " ├ version: $version "
    _checkUpdate $version
    _echo " └ revision: "`cat $gitlab_version | jq '.revision' | tr -d '"'` 1

    _echoTest "Project detail"
    _startTime
    project_data=$(mktemp)
    _curl --silent "$GITLAB_API/projects/$PROJECT_ID/?private_token=$TOKEN" > $project_data; td=`cat $project_data`; if [[ -z $td ]]; then _fail; else _ok; fi;
    _endTime
    _echo " ├ id: $PROJECT_ID" 1
    _echo " ├ name: "`cat $project_data | jq '.name' | tr -d '"'` 1
    _echo " └ url: "`cat $project_data | jq '.web_url' | tr -d '"'` 1

    _echoTest "Star project"
    _startTime
    _curl -XPOST --silent "$GITLAB_API/projects/$PROJECT_ID/star/" -d "private_token=$TOKEN" >&/dev/null && _ok || _fail
    _endTime

    _echoTest "Unstar project"
    _startTime
    _curl -XPOST --silent "$GITLAB_API/projects/$PROJECT_ID/unstar/" -d "private_token=$TOKEN" >&/dev/null && _ok || _fail
    _endTime

    _echoTest "Clone" 
    _startTime
    repo_url=$(echo $(cat $project_data | jq '.ssh_url_to_repo') | tr -d '"' | sed 's/\.vpn//')
    git clone --quiet $repo_url $tmp_dir && _ok || _fail
    _endTime
    _echo " └ git version: $(git --version | awk '{ print $3 }')" 1

    _echoTest "Change directory" 
    _startTime
    cd $tmp_dir && _ok || _fail
    _endTime

    _echoTest "Commit"
    _startTime
    echo "Test `date`
    " >> test.md || _echo $FAIL
    git add . && git commit --quiet -am "test `date`" && _ok || _fail
    _endTime

    _echoTest "Push to master"
    _startTime
    git push --quiet origin master && _ok || _fail
    _endTime

    _echoTest "Checkout to develop branch"
    _startTime
    git checkout --quiet -b develop && _ok || _fail
    _endTime

    _echoTest "Push to develop branch"
    _startTime
    git push --quiet origin develop >&/dev/null && git checkout --quiet master && _ok || _fail
    _endTime

    _echoTest "Create merge request"
    _startTime
    mr_data=$(mktemp)
    title="test `date`"
    _curl -XPOST --silent "$GITLAB_API/projects/$PROJECT_ID/merge_requests/" -d "private_token=$TOKEN&source_branch=master&target_branch=develop&title=$title" > $mr_data && _ok || _fail
    mr_id=$(cat $mr_data | jq '.iid')
    _endTime
    _echo " ├ id: $mr_id" 1
    _echo " ├ name: "`cat $mr_data | jq '.title' | tr -d '"'` 1
    _echo " └ url: "`cat $mr_data | jq '.web_url' | tr -d '"'` 1

    _echoTest "Add comment to merge request"
    _startTime
    mr_note=$(mktemp)
    _curl -XPOST --silent "$GITLAB_API/projects/$PROJECT_ID/merge_requests/$mr_id/notes" -d "private_token=$TOKEN&body=message%20test%20hi" > $mr_note && _ok || _fail
    _endTime

    _echoTest "Close merge request"
    _startTime
    mr_close=$(mktemp)
    _curl -XPUT --silent "$GITLAB_API/projects/$PROJECT_ID/merge_requests/$mr_id" -d "private_token=$TOKEN&state_event=close" > $mr_close && _ok || _fail
    _endTime

    cd ../
    rm -rf $tmp_dir
    _echo "" 1
}

main

ELAPSED_TIME=$(($SECONDS - $START_TIME))
_echo "Time: $(($ELAPSED_TIME/60)) minutes $(($ELAPSED_TIME%60)) seconds" 1
_echo "${green}done.${normal}" 1

exit 0