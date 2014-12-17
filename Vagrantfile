# Puppet version to install:
# 'original': As provided in the box
# 'latest': Installed from PuppetLabs repos
# 'x.y.z-k': Specific version, installed from PuppetLabs repos
puppetversion = '3.7.1-1'



Vagrant.configure("2") do |config|
  config.cache.auto_detect = true

  # See https://github.com/mitchellh/vagrant/issues/1673
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  {
    :Centos7 => {
      :box     => 'centos-7.x-64bit-puppet-3.x-vbox.4.3.14-1.box',
      :box_url => 'http://packages.vstone.eu/vagrant-boxes/centos/7.x/centos-7.x-64bit-puppet-3.x-vbox.4.3.14-1.box',
      :breed   => 'redhat',
    },
    :Centos65 => {
      :box     => 'centos65_64',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box',
      :breed   => 'redhat',
    },
    :Centos510 => {
      :box     => 'centos-5.10-64bit',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/centos-510-x64-virtualbox-puppet.box',
      :breed   => 'redhat',
    },
    :Ubuntu1404 => {
      :box     => 'trusty-server-cloudimg-amd64-vagrant-disk1.box',
      :box_url => 'https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box',
      :breed   => 'debian',
    },
    :Ubuntu1204 => {
      :box     => 'ubuntu-server-12042-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box',
      :breed   => 'debian',
    },
    :Ubuntu1004 => {
      :box     => 'ubuntu-server-12042-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box',
      :breed   => 'debian',
    },
    :Debian7 => {
      :box     => 'debian-70rc1-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210.box',
      :breed   => 'debian',
    },
    :Debian6 => {
      :box     => 'debian-607-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-607-x64-vbox4210.box',
      :breed   => 'debian',
    },
    :SuseLinux11 => {
      :box     => 'sles-11sp1-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/sles-11sp1-x64-vbox4210.box',
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
