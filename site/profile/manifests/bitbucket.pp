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
    command => "/vagrant/${bitbucket_installer} -q",
    unless  => '/bin/netstat -tln | grep -q ":7990"',
    require => File["/vagrant/${bitbucket_installer}"],
  }

  file { '/usr/bin/keytool':
    ensure => link,
    target => '/opt/atlassian/bitbucket/4.3.2/jre/bin/keytool',
  }

  # Add the Puppet CA as a trusted certificate authority because
  # the webhook add-on must use a trusted connection.
  java_ks { 'tomcat:cacerts':
    ensure       => latest,
    certificate  => "${::settings::certdir}/ca.pem",
    target       => '/opt/atlassian/bitbucket/4.3.2/jre/lib/security/cacerts',
    password     => 'changeit',
    trustcacerts => true,
    require      => [ Exec['Run Bitbucket Server Installer'], File['/usr/bin/keytool'] ],
  }

}
