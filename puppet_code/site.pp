## site.pp ##

# Disable filebucket by default for all File resources:
# http://docs.puppetlabs.com/pe/latest/release_notes.html#filebucket-resource-no-longer-created-by-default
File { backup => false }


node 'stash-server' {

  class { 'java' :
    version => present,
  }

  class { 'postgresql::globals':
    manage_package_repo => true,
    version             => '9.4',
  }

  include ::postgresql::server

  postgresql::server::db { 'stash':
    user     => 'stash',
    password => postgresql_password('stash', 'password'),
  }

  class { 'stash':
    javahome  => '/etc/alternatives/java_sdk',
    #dev.mode grants a 24-hour license for testing
    java_opts => '-Datlassian.dev.mode=true',
  }

  Class['java']                   ->
  Class['postgresql::globals']    ->
  Class['postgresql::server']     ->
  Postgresql::Server::Db['stash'] ->
  Class['stash']

}

node 'puppet-master'{

}

node default {
}

