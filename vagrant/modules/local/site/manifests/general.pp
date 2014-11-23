# General baseline, common to all the nodes
#
class site::general {

  tp::install { 'openssh': }

  tp::install { 'mailx': }
  
  tp::conf { 'hosts':
    template => 'site/hosts/hosts.erb',
  }

}
