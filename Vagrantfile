# Puppet version to install:
# 'original': As provided in the box
# 'latest': Installed from PuppetLabs repos
# 'x.y.z-k': Specific version, installed from PuppetLabs repos
puppetversion = 'latest'


Vagrant.configure("2") do |config|
  config.cache.auto_detect = true

  # See https://github.com/mitchellh/vagrant/issues/1673
  # config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  {
    :Centos7 => {
      :box     => 'centos7.box',
      :box_url => 'https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box',
      :breed   => 'redhat',
    },
    :Centos65 => {
      :box     => 'centos65_64',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box',
      :breed   => 'redhat6',
    },
    :Ubuntu1404 => {
      :box     => 'trusty-server-cloudimg-amd64-vagrant-disk1.box',
      :box_url => 'https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box',
      :breed   => 'debian',
    },
    :Ubuntu1204 => {
      :box     => 'ubuntu-server-12042-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box',
      :breed   => 'ubuntu1204',
    },
    :Debian7 => {
      :box     => 'debian-70rc1-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210.box',
      :breed   => 'debian',
    },
    :Debian6 => {
      :box     => 'debian-607-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-607-x64-vbox4210.box',
      :breed   => 'debian6',
    },
    :OpenSuse12_3 => {
      :box     => 'opensuse-12.3-64',
      :box_url => 'http://sourceforge.net/projects/opensusevagrant/files/12.3/opensuse-12.3-64.box/download',
      :breed   => 'suse',
    },
  }.each do |name,cfg|
    config.vm.define name do |local|
      local.vm.box = cfg[:box]
      local.vm.box_url = cfg[:box_url]
#      local.vm.boot_mode = :gui
      local.vm.host_name = ENV['VAGRANT_HOSTNAME'] || name.to_s.downcase.gsub(/_/, '-').concat(".example42.com")
      local.vm.provision "shell", path: 'vagrant/bin/setup-' + cfg[:breed] + '.sh', args: puppetversion
      local.vm.provision :puppet do |puppet|
        puppet.hiera_config_path = 'vagrant/hiera.yaml'
        puppet.working_directory = '/vagrant/vagrant/hieradata'
        puppet.manifests_path = "vagrant/manifests"
        puppet.module_path = [ '../.' , 'vagrant/modules/local' , 'vagrant/modules/public' ]
        puppet.manifest_file = "site.pp"
        puppet.options = [
         '--verbose',
         '--report',
         '--show_diff',
         '--pluginsync',
         '--summarize',
#         '--profile',
        '--evaltrace',
        '--trace',
#        '--debug',
#        '--parser future',
        ]
      end
    end
  end
end
