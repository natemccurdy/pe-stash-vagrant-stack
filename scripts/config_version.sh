#!/bin/bash
RUBY='/opt/puppetlabs/puppet/bin/ruby'
GIT='/usr/bin/git'

if [[ -e $1/$2/.r10k-deploy.json ]]; then
  $RUBY "${1}/${2}/scripts/code_manager_config_version.rb" "$1" "$2"
elif [[ -e /opt/puppetlabs/server/pe_version ]]; then
  $RUBY "${1}/${2}/scripts/config_version.rb" "$1" "$2"
elif $GIT --version > /dev/null 2>&1; then
  $GIT --git-dir "${1}/${2}/.git" rev-parse HEAD
else
  date +%s
fi

