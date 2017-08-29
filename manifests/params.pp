# Params class for tp
#
class tp::params {
  $tp_path = $::osfamily ? {
    'windows' => 'C:/ProgramData/PuppetLabs/puppet/bin/tp',
    'Darwin'  => '/usr/bin/tp',
    default   => '/usr/local/bin/tp',
  }
  $tp_dir = $::osfamily ? {
    'windows' => 'C:/ProgramData/PuppetLabs/puppet/etc/tp',
    default   => '/etc/tp',
  }
  $tp_owner = $::osfamily ? {
    'windows' => 'Administrator',
    default   => 'root',
  }
  $tp_group = $::osfamily ? {
    'windows' => 'Administrators',
    'Darwin'  => 'wheel',
    default   => 'root',
  }
  $check_service_command = $::osfamily ? {
    'RedHat' => $::operatingsystemmajrelease ? {
      '6'     => 'service',
      default => 'systemctl status',
    },
    'Suse'   => $::operatingsystemmajrelease ? {
      '11'     => 'service',
      default => 'systemctl status',
    },
    'Debian' =>  $::operatingsystemmajrelease ? {
      '7'     => 'service',
      '10.04' => 'service',
      '12.04' => 'service',
      '14.04' => 'service',
      default => 'systemctl status',
    },
    default  => 'puppet resource service',
  }
  $check_service_command_post = $::osfamily ? {
    'RedHat' => $::operatingsystemmajrelease ? {
      '6'     => 'status',
      default => '',
    },
    'Suse'   => $::operatingsystemmajrelease ? {
      '11'     => 'status',
      default => '',
    },
    'Debian' =>  $::operatingsystemmajrelease ? {
      '7'     => 'status',
      '10.04' => 'status',
      '12.04' => 'status',
      '14.04' => 'status',
      default => '',
    },
    default  => '',
  }
  $check_package_command = $::osfamily ? {
    'RedHat' => 'rpm -q',
    'Suse'   => 'rpm -q',
    'Debian' => 'dpkg -l',
    default  => 'puppet resource package',
  }
  $ruby_path = $::osfamily ? {
    'windows' => 'C:/ProgramData/PuppetLabs/puppet/bin/ruby',
    default   => '/opt/puppetlabs/puppet/bin/ruby',
  }

}
