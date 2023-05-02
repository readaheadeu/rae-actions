#!/bin/bash

#
# List GitHub Branches
#
# List all branches of a given GitHub repository and annotate them
# with their last commit timestamp. This script takes as input the
# repository name (specified as 'OWNER/REPOSITORY') and outputs a
# JSON formatted array of annotated branches as:
#
#     [
#         { "name": "<branch>", "date": "<timestamp>" },
#         ...
#     ]
#

set -eo pipefail

# Variable declarations

RAE_ACCEPT="Accept: application/vnd.github+json"
RAE_APIVERSION="X-GitHub-Api-Version: 2022-11-28"
RAE_BRANCH=""
RAE_BRANCHES=""
RAE_LIST=""
RAE_OUTPUT=""

# Parameter verification

RAE_REPOSITORY="$1"
if [[ -z "${RAE_REPOSITORY}" ]] ; then
        echo "Usage: $0 <owner/repository>"
        exit 1
fi

# Fetch list of branches from GitHub

RAE_BRANCHES=$(
        gh api \
                -H "${RAE_ACCEPT}" \
                -H "${RAE_APIVERSION}" \
                "/repos/${RAE_REPOSITORY}/branches" | \
            jq \
                -ce "[.[].name]"
)

# Read JSON array into bash array

readarray -t RAE_LIST < <(jq -cr ".[]" <<< "${RAE_BRANCHES}")

# Annotate the branches with their commit-date

RAE_OUTPUT=$(
        for RAE_BRANCH in "${RAE_LIST[@]}"; do
                gh api \
                        -H "${RAE_ACCEPT}" \
                        -H "${RAE_APIVERSION}" \
                        "/repos/${RAE_REPOSITORY}/branches/${RAE_BRANCH}" | \
                    jq \
                        -ce "{name: .name, date: .commit.commit.committer.date}"
        done | jq -ces
)

# Output annotated branches

echo "${RAE_OUTPUT}"
