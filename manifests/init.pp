#
# Centreon Configuration
#

class centreon_config (
  String $centreon_webapi_host     = 'http://localhost',
  String $centreon_webapi_port     = '80',
  String $centreon_login           = 'admin',
  String $centreon_admin_password  = 'p4ssw0rd',
  Optional[String] $host_alias     = undef,
  String $host_template            = undef,
  String $host_pooler              = 'Central',
  String $host_state               = 'enabled',
  Optional[String] $host_group     = '',
  Optional[Hash]   $configuration  = undef,
  String $script_path              = '/tmp'
) {

  case $::osfamily {
    'Debian': {
      $wrapper_packages = [
        'python-requests',
        'python-yaml'
      ]
      $python_path = '/usr/bin/python'
    }
    'RedHat': {
      $wrapper_packages = [
        'epel-release',
        'python34-requests',
        'python34-PyYAML'
      ]
      $python_path = '/usr/bin/python3'
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
  file { "$script_path/wrapper.py":
    content => template('centreon_config/wrapper.py.erb'),
    mode    => '0700',
    owner   => root,
    group   => root,
    require => Package[$wrapper_packages],
  }
  file { "$script_path/register.sh":
    content => template('centreon_config/register.sh.erb'),
    mode    => '0700',
    owner   => root,
    group   => root,
    require => Package[$wrapper_packages],
  }
  # Create file config
  file { "$script_path/config.yml":
    content => template('centreon_config/config.yml.erb'),
    mode    => '0640',
    owner   => root,
    group   => root,
    require => File["$script_path/wrapper.py"]
  }

  exec { 'Apply configuration using wrapper':
    command     => "$python_path $script_path/wrapper.py",
    subscribe   => File["$script_path/config.yml"],
    refreshonly => true,
    require     => [
      File["$script_path/wrapper.py"],
      File["$script_path/config.yml"],
      Package[$wrapper_packages]
    ]
  }
}
