class profile::stash_server {

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
    version   => '3.11.6',
    javahome  => '/etc/alternatives/java_sdk',
    #dev.mode grants a 24-hour license for testing
    java_opts => '-Datlassian.dev.mode=true',
  }

  Class['java']                   ->
  Class['postgresql::globals']    ->
  Class['postgresql::server']     ->
  Postgresql::Server::Db['stash'] ->
  Class['stash']

  # Add the Puppet CA as a trusted certificate authority because
  # the webhook add-on must use a trusted connection.
  java_ks { 'tomcat:cacerts':
    ensure       => latest,
    certificate  => "${::settings::certdir}/ca.pem",
    target       => '/etc/alternatives/java_sdk/jre/lib/security/cacerts',
    password     => 'changeit',
    trustcacerts => true,
    require      => Class['java']
  }

}
