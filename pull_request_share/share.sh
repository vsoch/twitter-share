#!/bin/bash

# Suggested by Github actions to be strict
set -e
set -o pipefail

################################################################################
# Global Variables (we can't use GITHUB_ prefix)
################################################################################

API_VERSION=v3
BASE=https://api.github.com
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
HEADER="Accept: application/vnd.github.${API_VERSION}+json;"
HEADER="${HEADER}; application/vnd.github.antiope-preview+json"
EXIT_CODE=${NO_BRANCH_DELETED_EXIT_CODE:-78}

# User Variables
MATCH_PATTERN=${MATCH_PATTERN:-".png"}
HASHTAG=${HASHTAG:-""}
CUSTOM_MESSAGE=${CUSTOM_MESSAGE:-""}
DATA_URL=${DATA_URL:-"https://www.github.com/vsoch/twitter-share"}
AT_USERNAME=${AT_USERNAME:-""}

# URLs
REPO_URL="${BASE}/repos/${GITHUB_REPOSITORY}"

################################################################################
# Helper Functions
################################################################################

response_fail() {

    echo "Error with token or response.";
    exit 1;

}

get_url() {

    RESPONSE=$(curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" "${1:-}")
    echo ${RESPONSE}
}

check_credentials() {

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        echo "You must include the GITHUB_TOKEN as an environment variable."
        exit 1
    fi

}

check_events_json() {

    if [[ ! -f "${GITHUB_EVENT_PATH}" ]]; then
        echo "Cannot find Github events file at ${GITHUB_EVENT_PATH}";
        exit 1;
    fi
    echo "Found ${GITHUB_EVENT_PATH}";

}


share_tweet() {

    PR_NUMBER="${1}"
    FILES_URL=${REPO_URL}/pulls/${PR_NUMBER}/files
    echo "Files URL is ${FILES_URL}"
    RESPONSE=$(get_url "${FILES_URL}")

    FILES=$(echo "${RESPONSE}" | jq --raw-output '.[] | {url: .raw_url, name: .filename, status: .status} | @base64')
    echo $FILES

    SHARE_FILES=""
    for FILE in ${FILES}; do
        DETAIL="$(echo "${FILE}" | base64 --decode)"
	STATUS=$(echo "${DETAIL}" | jq --raw-output '.status')
	URL=$(echo "${DETAIL}" | jq --raw-output '.url')
	NAME=$(echo "${DETAIL}" | jq --raw-output '.name')
        echo "Checking file ${NAME}";

        if [[ "${STATUS}" == "added" ]]; then
            echo "Found added file ${NAME}";
        fi

        # Does it match the pattern?
        if [[ ${NAME} == *${MATCH_PATTERN}* ]]; then
            echo "Pattern is matched."
            SHARE_FILES="${SHARE_FILES} ${URL}"
        fi
    done

    if [[ "${SHARE_FILES}" != "" ]]; then
            MESSAGE_FILE=$(mktemp /tmp/twitter-share.XXXXXX)            
            COMMENTS_URL="${REPO_URL}/issues/${PR_NUMBER}/comments"
            echo "${SHARE_FILES}" > $MESSAGE_FILE
            export AUTH_HEADER HEADER COMMENTS_URL API_VERSION GITHUB_TOKEN MESSAGE_FILE HASHTAG CUSTOM_MESSAGE 
            python3 /post_message.py
    else
        echo "No files to share."
    fi

}

main () {

    # path to file that contains the POST response of the event
    # Example: https://github.com/actions/bin/tree/master/debug
    # Value: /github/workflow/event.json
    check_events_json;

    # Get the name of the action that was triggered
    ACTION=$(jq --raw-output .action "${GITHUB_EVENT_PATH}");
    NUMBER=$(jq --raw-output .number "${GITHUB_EVENT_PATH}");
    MERGED=$(jq --raw-output .pull_request.merged "$GITHUB_EVENT_PATH");

    echo "DEBUG -> action: $ACTION merged: $MERGED"
    echo "Pull Request number is ${NUMBER}"

    #if [[ "$ACTION" != "closed" ]] || [[ "$MERGED" != "true" ]]; then
    #    exit "$EXIT_CODE";
    #fi
    check_credentials
    share_tweet ${NUMBER}

    # Only interested in newly opened 
    # https://developer.github.com/v3/activity/events/types/#pullrequestevent
    #if [[ "${MERGED}" == "false" ]]; then
    #    check_credentials
    #    share_tweet $NUMBER
    #fi
}

echo "==========================================================================
START: Running Share Tweet Image Action!";
main;
echo "==========================================================================
END: Running Share Tweet Image Action";
