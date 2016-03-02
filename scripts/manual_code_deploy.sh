#!/bin/bash

echo "==> Running r10k manually as pe-puppet to fetch new code"
sudo -u pe-puppet bash -c '/opt/puppetlabs/puppet/bin/r10k deploy environment -c /opt/puppetlabs/server/data/code-manager/r10k.yaml -p -v debug'

echo "==> Delete the code dir so file-sync can do its thing"
sudo rm -rf /etc/puppetlabs/code/*

# Set variables for the curl.
CERT="$(puppet agent --configprint hostcert)"
KEY="$(puppet agent --configprint hostprivkey)"
CACERT="$(puppet agent --configprint localcacert)"

echo "==> Hitting the file-sync commit endpoint at https://$(hostname -f):8140/file-sync/v1/commit"
/opt/puppetlabs/puppet/bin/curl -v -s --request POST \
                                --header "Content-Type: application/json" \
                                --data '{"commit-all": true}' \
                                --cert "$CERT" \
                                --key "$KEY" \
                                --cacert "$CACERT" \
                                "https://$(hostname -f):8140/file-sync/v1/commit" && echo


