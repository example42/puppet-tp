Vagrant.configure("2") do |config|
  config.cache.auto_detect = true
  {
    :Centos65 => {
      :box     => 'centos65_64',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box',
    },
    :Centos510 => {
      :box     => 'centos-5.10-64bit',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/centos-510-x64-virtualbox-puppet.box',
    },
    :Ubuntu1404 => {
      :box     => 'trusty-server-cloudimg-amd64-vagrant-disk1.box',
      :box_url => 'https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box',
    },
    :Ubuntu1204 => {
      :box     => 'ubuntu-server-12042-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box',
    },
    :Ubuntu1004 => {
      :box     => 'ubuntu-server-12042-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box',
    },
    :Debian7 => {
      :box     => 'debian-70rc1-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210.box',
    },
    :Debian6 => {
      :box     => 'debian-607-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/debian-607-x64-vbox4210.box',
    },
    :SuseLinux11 => {
      :box     => 'sles-11sp1-x64-vbox4210',
      :box_url => 'http://puppet-vagrant-boxes.puppetlabs.com/sles-11sp1-x64-vbox4210.box',
    },
  }.each do |name,cfg|
    config.vm.define name do |local|
      local.vm.box = cfg[:box]
      local.vm.box_url = cfg[:box_url]
#      local.vm.boot_mode = :gui
      local.vm.host_name = ENV['VAGRANT_HOSTNAME'] || name.to_s.downcase.gsub(/_/, '-').concat(".example42.com")
      local.vm.provision :puppet do |puppet|
        puppet.hiera_config_path = 'vagrant/hiera.yaml'
        puppet.working_directory = '/vagrant/vagrant/hieradata'
        puppet.manifests_path = "vagrant/manifests"
        puppet.module_path = [ '.' , 'vagrant/modules' ]
        puppet.manifest_file = "init.pp"
        puppet.options = [
         '--verbose',
         '--report',
         '--show_diff',
         '--pluginsync',
         '--summarize',
#         '--profile',
#        '--evaltrace',
        '--debug',
#        '--parser future',
        ]
      end
    end
  end
end
