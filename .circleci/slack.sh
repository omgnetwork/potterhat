#!/bin/sh -e
#
# Stupid and Simple Slack Notifier.
#

LC_ALL=en_US.UTF-8; export LC_ALL
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR=$(mktemp -d)
trap 'rm -rf $WORKDIR' 0 1 2 3 6 14 15

NEWLINE="
"

## Utils
##

printe() {
    printf >&2 "%s\\n" "$@"
}

err() {
    printf >&2 "%s: %s\\n" "$(basename "$0")" "$*"
}

_escape() {
    printf "%s" "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr -d "\n"
}

_colonize() {
    var=$1

    if [ -n "$var" ]; then
        var="$var,"
    fi

    printf "%s" "$var"
}

_trim() {
    var=$1
    var=${var#"${var%%[![:space:]]*}"}
    var=${var%"${var##*[![:space:]]}"}
    printf "%s" "$var"
}


## Arguments handling
##

print_usage() {
    printe "\
Usage: $0 [ARGS] MESSAGE

Send a message to Slack as an attachment. For information about ARGS, see ARGS.
To configure a notification endpoint, see ENVIRONMENT VARIABLES.

ARGS:

    -c COLOR           Color of the message strip.

    -m                 Enable Markdown-like formatting (\"Mrkdwn\") in message.

    -t FALLBACK        Message to send users with plain text client. The value of
                       this argument should be similar to MESSAGE but with
                       formatting syntaxes removed.

    -f IDX:KEY=VALUE   A specification to build attachment fields. For example:
                       \`-f 0:key1=value -f 0:key2=value -f 1:key1=value\`
                       will result in the following JSON:

                           [
                               {\"key1\":\"value\",\"key2\":\"value\"},
                               {\"key1\":\"value\"},
                           ]

                       The index is arbitrary and is only used for sorting and
                       grouping.

ENVIRONMENT VARIABLES:

    SLACK_WEBHOOK    Slack webhook URL to send message to.
" # EOF
}

OPTIND=1

_color=""
_markdown=0
_fallback=""
_fields=""

while getopts "c:mt:f:" opt; do
    case "$opt" in
        c ) _color=$OPTARG;;
        m ) _markdown=1;;
        t ) _fallback=$OPTARG;;
        f ) _fields="$_fields$OPTARG$NEWLINE";;
        * ) print_usage; exit 1;;
    esac
done

shift $((OPTIND-1))
if [ "${1:-}" = "--" ]; then
    shift
fi

if [ -z "$SLACK_WEBHOOK" ]; then
    err "Environment variable SLACK_WEBHOOK has not been configured."
    exit 2
fi

if [ -z "$*" ]; then
    err "TEXT must be present."
    exit 1
fi


## Payload building
## Building JSON with POSIX sh is not THAT bad.
##

_message=$*
_payload_i=

# Fallback text
#

if [ -n "$_fallback" ]; then
    _payload_i="\
$(_colonize "$_payload_i")\
\"fallback\":\"$(_escape "$_fallback")\""
fi

# Markdown
#

if [ "$_markdown" = 1 ]; then
    _payload_i="\
$(_colonize "$_payload_i")\
\"mrkdwn\":true"
fi

# Color
#

if [ -n "$_color" ]; then
    _payload_i="\
$(_colonize "$_payload_i")\
\"color\":\"$(_escape "$_color")\""
fi

# Fields
#

if [ -n "$_fields" ]; then
    field_i=
    tmp_data=
    last_idx=

    echo "${_fields%%$NEWLINE}" | sort -n > "$WORKDIR/_fields_tmp"

    while read -r field; do
        idx=${field%%:*}
        rest=${field##$idx:}

        if [ "$last_idx" != "$idx" ] && [ -n "$tmp_data" ]; then
            field_i="$(_colonize "$field_i"){$tmp_data}"
            tmp_data=
        fi

        key=${rest%%=*}
        value=${rest##$key=}
        tmp_data="\
$(_colonize "$tmp_data")\
\"$(_escape "$key")\":\
\"$(_escape "$value")\""

        last_idx="$idx"
    done < "$WORKDIR/_fields_tmp"

    if [ -n "$tmp_data" ]; then
        field_i="$(_colonize "$field_i"){$tmp_data}"
    fi

    _payload_i="\
$(_colonize "$_payload_i")\
\"fields\":[${field_i}]"
fi

# Text
#

_payload_i="\
$(_colonize "$_payload_i")\
\"text\":\"$(_escape "$_message")\""


## Finalize
##

exec curl -X POST \
     -H 'Content-Type: application/json' \
     --data "{\"attachments\":[{${_payload_i}}]}" \
     "$SLACK_WEBHOOK"
