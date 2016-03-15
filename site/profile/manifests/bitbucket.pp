class profile::bitbucket {

  $bitbucket_version   = '4.4.1'
  $bitbucket_installer = "atlassian-bitbucket-${bitbucket_version}-x64.bin"
  $bitbucket_home      = '/var/atlassian/application-data/bitbucket'

  service { 'puppet':
    ensure => stopped,
    enable => false,
  }

  include ::epel

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
    command   => "/vagrant/${bitbucket_installer} -q",
    creates   => "/opt/atlassian/bitbucket/${bitbucket_version}/bin/setenv.sh",
    logoutput => true,
    require   => File["/vagrant/${bitbucket_installer}"],
  }

  file { '/usr/bin/keytool':
    ensure => link,
    target => "/opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool",
  }

  service { 'atlbitbucket':
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    require    => Exec['Run Bitbucket Server Installer'],
  }

  # Add the Puppet CA as a trusted certificate authority because
  # the webhook add-on must use a trusted connection.
  java_ks { $::settings::server :
    ensure       => latest,
    certificate  => "${::settings::certdir}/ca.pem",
    target       => "/opt/atlassian/bitbucket/${bitbucket_version}/jre/lib/security/cacerts",
    password     => 'changeit',
    trustcacerts => true,
    require      => [ Exec['Run Bitbucket Server Installer'], File['/usr/bin/keytool'] ],
    notify       => Service['atlbitbucket'],
  }

  file_line { 'bitbucket dev mode':
    ensure => present,
    path   => "/opt/atlassian/bitbucket/${bitbucket_version}/bin/setenv.sh",
    line   => 'export JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${BITBUCKET_HOME_MINUSD} -Datlassian.dev.mode=true"', #lint:ignore:single_quote_string_with_variables
    match  => '^export JAVA_OPTS=',
    notify => Service['atlbitbucket'],
  }

  file { "${bitbucket_home}/external-hooks":
    ensure  => 'directory',
    owner   => 'atlbitbucket',
    group   => 'atlbitbucket',
    mode    => '0775',
    require => Exec['Run Bitbucket Server Installer'],
  }

  # The commit here is where I've made some BASH fixes to the scripts.
  vcsrepo { "${bitbucket_home}/external-hooks/puppet-git-hooks":
    ensure   => present,
    provider => 'git',
    source   => 'https://github.com/drwahl/puppet-git-hooks.git',
    revision => '5bd7ddeda8f74a00bdb10aad674997d638f3b9b6',
    owner    => 'atlbitbucket',
    group    => 'atlbitbucket',
    require  => [ File["${bitbucket_home}/external-hooks"], Exec['Run Bitbucket Server Installer'] ],
  }

  # Add ruby and the puppet-lint gem for the pre-receive hooks.
  package { 'ruby':
    ensure => present,
  }

  package { 'puppet-lint':
    ensure   => present,
    provider => 'gem',
    require  => Package['ruby'],
  }

}
