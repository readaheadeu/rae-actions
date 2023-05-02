#!/bin/bash

#
# Delete Matching Expired GitHub Branches
#
# Delete all matching branches of a GitHub repository that are older
# than a specified expiration date. The input to this script must be
# a JSON array of annotated branches with at least these fields:
#
#     [
#         { "name": "<branch>", "date": "<timestamp>", ... },
#         ...
#     ]
#

set -eo pipefail

# Variable declarations

RAE_ACCEPT="Accept: application/vnd.github+json"
RAE_APIVERSION="X-GitHub-Api-Version: 2022-11-28"
RAE_BRANCH=""
RAE_BRANCHES=""
RAE_DATE=""
RAE_LIST=""
RAE_OUTPUT=""
RAE_REPOSITORY=""
RAE_WILDCARD=""

# Parameter verification

RAE_REPOSITORY="$1"
if [[ -z "${RAE_REPOSITORY}" ]] ; then
        echo "Usage: $0 <owner/repository> <wildcard> <date>"
        exit 1
fi

RAE_WILDCARD="$2"
if [[ -z "${RAE_WILDCARD}" ]] ; then
        echo "Usage: $0 <owner/repository> <wildcard> <date>"
        exit 1
fi

RAE_DATE="$3"
if [[ -z "${RAE_DATE}" ]] ; then
        echo "Usage: $0 <owner/repository> <wildcard> <date>"
        exit 1
fi

# Read JSON array into bash array

readarray -t RAE_LIST < <(jq -c ".[]")

# Convert expiration date into unix-timestamp

RAE_DATE="$(date --date="${RAE_DATE}" "+%s")"

# Filter branches and delete matching ones

RAE_OUTPUT=$(
        for RAE_BRANCH in "${RAE_LIST[@]}"; do
                name="$(jq -cr ".name" <<< "${RAE_BRANCH}")"
                date="$(jq -cr ".date" <<< "${RAE_BRANCH}")"
                date="$(date --date="${date}" "+%s")"

                if [[ "${name}" != ${RAE_WILDCARD} ]] ; then
                        echo >&2 "Skip non-matching branch: ${name}"
                        continue
                fi

                if (( ${date} >= ${RAE_DATE} )) ; then
                        echo >&2 "Skip non-expired branch: ${name}"
                        continue
                fi

                echo >&2 "Delete matching expired branch: ${name}"

                gh api \
                        -H "${RAE_ACCEPT}" \
                        -H "${RAE_APIVERSION}" \
                        -X "DELETE" \
                        "/repos/${RAE_REPOSITORY}/git/refs/heads/${name}"

                jq -c ".name" <<< "${RAE_BRANCH}"
        done | jq -ces
)

# Output annotated branches

echo "${RAE_OUTPUT}"
