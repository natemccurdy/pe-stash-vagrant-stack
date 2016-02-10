## site.pp ##

# Disable filebucket by default for all File resources:
# http://docs.puppetlabs.com/pe/latest/release_notes.html#filebucket-resource-no-longer-created-by-default
File { backup => false }


node 'stash-server' {

  include ::epel

  $bitbucket_installer = 'atlassian-bitbucket-4.3.2-x64.bin'

  # Get BitBucket
  include ::archive
  archive { "/vagrant/${bitbucket_installer}":
    ensure  => present,
    source  => "https://www.atlassian.com/software/stash/downloads/binary/${bitbucket_installer}",
    creates => "/vagrant/${bitbucket_installer}",
    extract => false,
    cleanup => false,
  }
  file { "/vagrant/${bitbucket_installer}":
    mode    => '0755',
    require => Archive["/vagrant/${bitbucket_installer}"],
  }

  # Setup Bitbucket
  exec { 'Run Bitbucket Server Installer':
    command => "/vagrant/${bitbucket_installer} -q",
    unless  => '/bin/netstat -tln | grep -q ":7990"',
    require => File["/vagrant/${bitbucket_installer}"],
  }

}

node 'puppet-master'{
  include ::profile::master
  include ::profile::code_manager
}

node default {
}

