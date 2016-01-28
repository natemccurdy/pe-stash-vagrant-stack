#!/bin/bash

echo "==> Running r10k manually as pe-puppet to fetch new code"
sudo -u pe-puppet bash -c 'r10k deploy environment -c /opt/puppetlabs/server/data/code-manager/r10k.yaml -p -v debug'

echo "==> Delete the code dir so file-sync can do its thing"
sudo rm -rf /etc/puppetlabs/code/*

# Determine paths to certs.
certname="$(puppet agent --configprint certname)"
certdir="$(puppet agent --configprint certdir)"

# Set variables for the curl.
cert="${certdir}/${certname}.pem"
key="$(puppet agent --configprint privatekeydir)/${certname}.pem"
cacert="${certdir}/ca.pem"

echo "==> Hitting the file-sync commit endpoint at https://$(hostname -f):8140/file-sync/v1/commit"
/opt/puppetlabs/puppet/bin/curl -v -s --request POST --header "Content-Type: application/json" --data '{"commit-all": true}' \
                                --cert "$cert" \
                                --key "$key" \
                                --cacert "$cacert" \
                                "https://$(hostname -f):8140/file-sync/v1/commit" && echo


