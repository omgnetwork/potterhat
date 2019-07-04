#!/bin/sh -e
#
# Notify Slack for various scenarios.
#

BASE_DIR=$(cd "$(dirname "$0")/.." || exit; pwd -P)
SLACK_SH="$BASE_DIR/.circleci/slack.sh"

cd "$BASE_DIR" || exit 1

if [ -z "$CIRCLE_PROJECT_REPONAME" ] ||
       [ -z "$CIRCLE_PROJECT_USERNAME" ] ||
       [ -z "$CIRCLE_WORKFLOW_ID" ] ||
       [ -z "$CIRCLE_JOB" ]; then
    printf >&2 "Not running under CircleCI?\\n"
    exit 1
fi


## Commands
##

cmd_success() {
    repo="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"

    message=
    message_f=
    fieldargs=

    if [ -n "$CIRCLE_TAG" ]; then
        message_f="$repo tag ${CIRCLE_TAG} has been successfully built"
        message=":white_check_mark: *$repo* tag *${CIRCLE_TAG}* has been successfully built"
        fieldargs="$fieldargs -f0:title=Tag"
        fieldargs="$fieldargs -f0:value=<https://github.com/$repo/releases/tag/${CIRCLE_TAG}|${CIRCLE_TAG}>"
        fieldargs="$fieldargs -f0:short=true"

    elif [ -n "$CIRCLE_BRANCH" ]; then
        message_f="$repo branch ${CIRCLE_BRANCH} has been successfully built"
        message=":white_check_mark: *$repo* branch *${CIRCLE_BRANCH}* has been successfully built"
        fieldargs="$fieldargs -f0:title=Branch"
        fieldargs="$fieldargs -f0:value=<https://github.com/$repo/tree/${CIRCLE_BRANCH}|${CIRCLE_BRANCH}>"
        fieldargs="$fieldargs -f0:short=true"
    fi

    if [ -n "$CIRCLE_BUILD_NUM" ]; then
        fieldargs="$fieldargs -f1:title=Build"
        fieldargs="$fieldargs -f1:value=<https://circleci.com/gh/$repo/${CIRCLE_BUILD_NUM}|${CIRCLE_BUILD_NUM}>"
        fieldargs="$fieldargs -f1:short=true"
    fi

    # shellcheck disable=SC2086
    sh "$SLACK_SH" \
       -c "#1cbf43" \
       -t "$message_f" \
       $fieldargs \
       -m "$message"
}

cmd_failure() {
    repo="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"

    message=
    message_f=
    fieldargs=

    if [ -n "$CIRCLE_TAG" ]; then
        message_f="$repo tag ${CIRCLE_TAG} has failed during ${CIRCLE_JOB}"
        message=":no_good: *$repo* tag *${CIRCLE_TAG}* has failed during ${CIRCLE_JOB}"
        fieldargs="$fieldargs -f0:title=Tag"
        fieldargs="$fieldargs -f0:value=<https://github.com/$repo/releases/tag/${CIRCLE_TAG}|${CIRCLE_TAG}>"
        fieldargs="$fieldargs -f0:short=true"

    elif [ -n "$CIRCLE_BRANCH" ]; then
        message_f="$repo branch ${CIRCLE_BRANCH} has failed during ${CIRCLE_JOB}"
        message=":no_good: *$repo* branch *${CIRCLE_BRANCH}* has failed during ${CIRCLE_JOB}"
        fieldargs="$fieldargs -f0:title=Branch"
        fieldargs="$fieldargs -f0:value=<https://github.com/$repo/tree/${CIRCLE_BRANCH}|${CIRCLE_BRANCH}>"
        fieldargs="$fieldargs -f0:short=true"
    fi

    if [ -n "$CIRCLE_BUILD_NUM" ]; then
        fieldargs="$fieldargs -f1:title=Build"
        fieldargs="$fieldargs -f1:value=<https://circleci.com/gh/$repo/${CIRCLE_BUILD_NUM}|${CIRCLE_BUILD_NUM}>"
        fieldargs="$fieldargs -f1:short=true"
    fi

    # shellcheck disable=SC2086
    sh "$SLACK_SH" \
       -c "#ed2c5c" \
       -t "$message_f" \
       $fieldargs \
       -m "$message"
}

cmd_deploy() {
    if [ -z "$DEPLOY_DOMAIN" ] || [ -z "$IMAGE_NAME" ]; then
        printf >&2 "Deploy metadata not present. Not sending notifications.\\n"
        exit
    fi

    message_f="${DEPLOY_DOMAIN} has been deployed"
    message=":tada: *${DEPLOY_DOMAIN}* has been deployed"

    if command -v git >/dev/null && tag=$(git rev-parse --short HEAD); then
        message_f="$message_f with ${IMAGE_NAME}:${tag}"
        message="$message with ${IMAGE_NAME}:${tag}"
    fi

    # shellcheck disable=SC2086
    sh "$SLACK_SH" \
       -c "#5f31d9" \
       -t "$message_f" \
       -m "$message"
}


## Dispatching commands
##

if [ $# -gt 0 ]; then
    COMMAND=$1; shift
fi

case "$COMMAND" in
    success ) cmd_success || true;;
    failure ) cmd_failure || true;;
    deploy )  cmd_deploy  || true;;
    * )
        printf >&2 "Not a valid command.\\n"
        exit 1
        ;;
esac
