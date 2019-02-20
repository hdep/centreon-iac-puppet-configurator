#
# Centreon Configuration
#

class centreon_config (
  String $centreon_webapi_host    = 'http://localhost',
  String $centreon_webapi_port    = '80',
  String $centreon_admin_password = 'p4ssw0rd',
  Hash   $configuration           = undef
) {


  if $configuration == undef {
    fail ('FATAL - You must set values in the variable *configuration*')
  }


  case $::osfamily {
    'Debian': {
      $wrapper_packages = [
        'python-requests',
        'python-yaml'
      ]
    }
    'RedHat': {
      $wrapper_packages = [
        'epel-release',
        'python34-requests',
        'python34-PyYAML'
      ]
    }
    default: {
      fail ('$::osfamily is not supported')
    }
  }

  # install requirement for wrapper.py
  package { $wrapper_packages:
    ensure  => latest,
  }

  # Create wrapper file
  file { '/tmp/wrapper.py':
    content => template('centreon/wrapper.py.erb'),
    mode    => '0755',
    require => Package[$wrapper_packages],
  }

  # Create file config
  file { '/tmp/config.yml':
    content => inline_template('<%= @configuration.to_yaml %>'),
    mode    => '0644',
    require => File['/tmp/wrapper.py']
  }

  exec { 'Apply configuration using wrapper':
    command => '/usr/bin/python3 /tmp/wrapper.py',
    require => [
      File['/tmp/wrapper.py'],
      File['/tmp/config.yml'],
      Package[$wrapper_packages]
    ]
  }
}
