## site.pp ##

# Disable filebucket by default for all File resources:
# http://docs.puppetlabs.com/pe/latest/release_notes.html#filebucket-resource-no-longer-created-by-default
File { backup => false }


node 'stash-server' {
  include ::profile::stash_server
}

node 'puppet-master'{
  include ::profile::master
  include ::profile::code_manager
}

node default {
}

