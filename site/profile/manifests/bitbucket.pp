class profile::bitbucket {

  service { 'puppet':
    ensure => stopped,
    enable => false,
  }

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
    command   => "/vagrant/${bitbucket_installer} -q",
    unless    => '/bin/netstat -tln | grep -q ":7990"',
    logoutput => true,
    require   => File["/vagrant/${bitbucket_installer}"],
  }

  file { '/usr/bin/keytool':
    ensure => link,
    target => '/opt/atlassian/bitbucket/4.3.2/jre/bin/keytool',
  }

  service { 'atlbitbucket':
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    require    => Exec['Run Bitbucket Server Installer'],
  }

  # Add the Puppet CA as a trusted certificate authority because
  # the webhook add-on must use a trusted connection.
  java_ks { 'puppet-server':
    ensure       => latest,
    certificate  => "${::settings::certdir}/ca.pem",
    target       => '/opt/atlassian/bitbucket/4.3.2/jre/lib/security/cacerts',
    password     => 'changeit',
    trustcacerts => true,
    require      => [ Exec['Run Bitbucket Server Installer'], File['/usr/bin/keytool'] ],
    notify       => Service['atlbitbucket'],
  }

  file_line { 'bitbucket dev mode':
    ensure => present,
    path   => '/opt/atlassian/bitbucket/4.3.2/bin/setenv.sh',
    line   => 'export JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${BITBUCKET_HOME_MINUSD} -Datlassian.dev.mode=true"', #lint:ignore:single_quote_string_with_variables
    match  => '^export JAVA_OPTS=',
    notify => Service['atlbitbucket'],
  }

}
