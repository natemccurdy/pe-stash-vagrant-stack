#!/bin/bash
#
# This script is meant to be called by the external-hooks add-on for Stash (Bitbucket):
#     https://marketplace.atlassian.com/plugins/com.ngs.stash.externalhooks.external-hooks/server/overview
#
# Make sure to pass the values for -k -p and -t on separate lines. e.g:
#   -k (optional)
#   -p puppet.company.com
#   -t 1234567890abcdef...
#

logger "$0 triggered to deploy ${STASH_REPO_NAME} by ${STASH_USER_NAME}"

usage() {
  cat <<USAGE

${0} [OPTIONS]
  -s, (optional) Including this will enable SSL verification.
  -p, --puppet-host [FQDN]
      The target FQDN of the Puppet Master to post to.
        example: puppet01.company.com
  -t, --token
      The RBAC token of a user authorized to deploy environments.
USAGE

  exit 1
}

while getopts ":sp:t:" opt; do
  case "${opt}" in
    k) ssl_auth=''
      ;;
    p) master="${OPTARG##* }"
      ;;
    t) token="${OPTARG##* }"
      ;;
    *) usage
      ;;
  esac
done
shift $((OPTIND-1))

if [[ -z $master ]] || [[ -z $token ]]; then
  logger "$0: ERROR - missing parameters"
  usage
fi

# The external-hooks script passes the following on stdin:
#
# "old_hash new_hash ref/ref/ref"
#
# for example:
# "00000000000000000000000 ad91e3697d0711985e06d5b refs/heads/production"
#
# All we care about is the branch name at the very end.
# We are using BASH's parameter expansion to strip all text to the left
# of, and including, the last '/'.
while read -r stdin; do
  branch=${stdin##*/}
done

if [[ -z $branch ]]; then
  logger -s "$0: ERROR - Could not determine a branch to synchronize to an environment"
  exit 1
fi

logger "Deploying ${STASH_REPO_NAME}:${branch} to ${master}"

# CURL the code-manager deploy API endpoint.
/bin/curl ${ssl_auth:--k} -s --request POST \
          --header "Content-Type: application/json" \
          --header "X-Authentication: ${token}" \
          --data   "{ \"environments\": [\"${branch}\"], \"wait\": true }"
          "https://${master}:8170/code-manager/v1/deploys"

