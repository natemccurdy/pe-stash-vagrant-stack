#!/bin/bash
#
# This script is meant to be called by the external-hooks add-on for Stash (Bitbucket):
#     https://marketplace.atlassian.com/plugins/com.ngs.stash.externalhooks.external-hooks/server/overview
#
# Make sure to pass the values for -p and -t on separate lines. e.g:
#   -p puppet.company.com
#   -t 1234567890abcdef...
#

logger "$0 triggered to deploy ${STASH_REPO_NAME} by ${STASH_USER_NAME}"

usage() {
  echo
  echo "${0} [OPTIONS]"
  echo "  -p, --puppet-host [FQDN]"
  echo "      The target FQDN of the Puppet Master to post to"
  echo "        example: puppet01.company.com"
  echo "  -t, --token"
  echo "      The RBAC token of a user authorized to deploy environments"
  echo
  exit 1
}

while getopts ":p:t:" opt; do
  case "${opt}" in
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
# old_hash new_hash ref/ref/ref
#
# for example:
# 0000000000000000000000000000000000000000 ad91e3697d0711985e06d5bbbf6a7c5dc3b657f7 refs/heads/production
#
# All we care about is refs/heads/<branch_name> to that we can deploy a specific environment
#
while read -r from_ref to_ref ref_name; do
  branch=${ref_name##*/}
done

if [[ -z $branch ]]; then
  logger -s "$0: ERROR - Could not determine a branch to synchronize to an environment"
  exit 1
fi

deploy_url="https://${master}:8170/code-manager/v1/deploys"
post_data="'{ \"environments\": [\"${branch}\"], \"wait\": true }'"

logger "Deploying ${STASH_REPO_NAME}:${branch} to ${master}"

# eval is used here because there's a bunch of quotes and special characters being used in this curl command.
eval "/bin/curl -k -X POST -H 'Content-Type: application/json' -H 'X-Authentication: ${token}' -d $post_data $deploy_url"

