# Params class for tp
#
class tp::params {
  $tp_path = $facts['os']['family'] ? {
    'windows' => "${facts['env_windows_installdir']}/bin/tp",
    default   => '/usr/local/bin/tp',
  }
  $tp_dir = $facts['os']['family'] ? {
    'windows' => 'C:/ProgramData/PuppetLabs/puppet/etc/tp',
    default   => '/etc/tp',
  }
  $tp_owner = $facts['os']['family'] ? {
    'windows' => 'Administrator',
    default   => 'root',
  }
  $tp_group = $facts['os']['family'] ? {
    'windows' => 'Administrators',
    'Darwin'  => 'wheel',
    default   => 'root',
  }
  $tp_mode = $facts['os']['family'] ? {
    'windows' => '0755',
    default   => '0755',
  }
  $check_service_command = $facts['os']['family'] ? {
    'RedHat' => $facts['os']['release']['major'] ? {
      '6'     => 'service',
      default => 'systemctl status',
    },
    'Suse'   => $facts['os']['release']['major'] ? {
      '11'     => 'service',
      default => 'systemctl status',
    },
    'Debian' =>  $facts['os']['release']['major'] ? {
      '7'     => 'service',
      '10.04' => 'service',
      '12.04' => 'service',
      '14.04' => 'service',
      default => 'systemctl status',
    },
    default  => 'puppet resource service',
  }
  $check_service_command_post = $facts['os']['family'] ? {
    'RedHat' => $facts['os']['release']['major'] ? {
      '6'     => 'status',
      default => '',
    },
    'Suse'   => $facts['os']['release']['major'] ? {
      '11'     => 'status',
      default => '',
    },
    'Debian' =>  $facts['os']['release']['major'] ? {
      '7'     => 'status',
      '10.04' => 'status',
      '12.04' => 'status',
      '14.04' => 'status',
      default => '',
    },
    default  => '',
  }
  $check_package_command = $facts['os']['family'] ? {
    'RedHat' => 'rpm -q',
    'Suse'   => 'rpm -q',
    'Debian' => 'dpkg -l',
    default  => 'puppet resource package',
  }
  $ruby_path = $facts['os']['family'] ? {
    'windows' => "${facts['env_windows_installdir']}/puppet/bin/ruby.exe",
    default   => '/opt/puppetlabs/puppet/bin/ruby',
  }

}
