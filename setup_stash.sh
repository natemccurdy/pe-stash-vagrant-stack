#!/bin/bash

stash_url='http://10.20.1.23:7990/'
creds='admin:admin'

curl -u $creds -X POST "${stash_url}/rest/api/1.0/admin/users?name=r10k&password=puppet&displayName=r10k&emailAddress=r10k@puppet.com"
