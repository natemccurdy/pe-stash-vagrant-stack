class profile::master {

  service { 'puppet':
    ensure => stopped,
    enable => false,
  }

  #Lay down update-classes.sh for use in r10k postrun_command
  #This is configured via the pe_r10k::postrun key in hiera
  file { '/usr/local/bin/update-classes.sh' :
    ensure => file,
    source => 'puppet:///modules/profile/update-classes.sh',
    mode   => '0755',
  }

  #https://docs.puppetlabs.com/puppet/latest/reference/config_file_environment.html#environmenttimeout
  ini_setting { 'environment_timeout = unlimited':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'environment_timeout',
    value   => 'unlimited',
    notify  => Service['pe-puppetserver'],
  }

}

