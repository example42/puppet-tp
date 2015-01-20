# General baseline, common to all the nodes
#
class site::general {

  tp::install { 'openssh': }

  # In Vagrant we use puppet apply so we disable the service
  tp::install { 'puppet':
    settings_hash => {
      service_enable => false,
      service_ensure => stopped,
    }
  }
  tp::conf { 'puppet':
    template => 'site/puppet/puppet.conf.erb',
  }
    
  tp::install { 'mailx': }
  
  #  tp::conf { 'hosts':
  #  template => 'site/hosts/hosts.erb',
  # }

}
