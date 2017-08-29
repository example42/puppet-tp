require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','openssh','elasticsearch','sysdig','puppet-agent']

describe 'tp::test', :type => :define do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))

        # Default params
        default_file_params = {
          'ensure'  => 'present',
          'mode'    => '0755',
          'owner'   => 'root',
          'group '  => 'root',
#          'content' => template($template),
          'tag'     => 'tp_test',
        }

        # Resource counts with normal tp::test
        total_count = 2 # tp::test + file
        package_count = 0
        service_count = 0
        exec_count = 0
        file_count = 1

        # Define if there's a service to check
        if appdata['service_name']
          has_service = true
        else
          has_service = false
        end

        # Interate contexts over os and over app
        context "with app #{app}" do
          let(:title) { app }

          context 'without any param' do
            it { is_expected.to compile }
            it { should have_file_resource_count(file_count) }
            it { should have_resource_count(total_count) }
          end
          context 'with ensure => absent' do
            let(:params) { { 'ensure' => 'absent' } }
            it { is_expected.to contain_file("/etc/tp/test/#{app}").with('ensure' => 'absent') }
          end
        end
      end
    end
  end
end
