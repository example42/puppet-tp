require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','openssh','elasticsearch','sysdig']

describe 'tp::stdmod', :type => :define do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))

        # Default params
        default_package_params = {
          'ensure'  => 'present',
        }
        default_service_params = {
          'ensure'  => 'running',
          'enable'  => true,
        }
        default_file_params = {
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
        }

        # Resource counts with normal tp::install + package + service
        total_count = 1
        package_count = 0
        service_count = 0
        exec_count = 0
        file_count = 0
        has_repo = false

        # Define if there's a service to check
        if appdata['service_name']
          has_service = true
          total_count = total_count.to_i + 1
          service_count = service_count.to_i + 1
        else
          has_service = false
        end
        # Define if a package is installed
        if appdata['package_name']
          total_count = total_count.to_i + 1
          package_count = package_count.to_i + 1
        end

        # Interate contexts over os and over app
        context "with app #{app}" do
          let(:title) { app }

          context 'without any param' do
            it { is_expected.to compile.with_all_deps }
            it { should have_tp__stdmod_resource_count(1) }
            it { should have_package_resource_count(package_count) }
            it { is_expected.to contain_package(appdata['package_name']).only_with(default_package_params) }
            if has_service
              it { should have_service_resource_count(service_count) }
              it { is_expected.to contain_service(appdata['service_name']).only_with(default_service_params) }
            end
            it { should have_exec_resource_count(exec_count) }
            it { should have_file_resource_count(file_count) }
            it { should have_resource_count(total_count) }
          end
          context 'with package_ensure => absent' do
            let(:params) { { 'package_ensure' => 'absent' } }
            it { is_expected.to contain_package(appdata['package_name']).only_with(default_package_params.merge('ensure' => 'absent')) }
            if has_service
              it { is_expected.to contain_service(appdata['service_name']).only_with(default_service_params.merge('ensure' => 'stopped', 'enable' => false)) }
            end
          end
          context 'with debug => true and debug_dir => /var/tmp' do
            let(:params) do {
              'debug'     => true,
              'debug_dir' => '/var/tmp',
            } end
            it { is_expected.to contain_file("tp_stdmod_debug_#{app}").with('ensure' => 'file', 'path' => "/var/tmp/tp_stdmod_debug_#{app}") }
          end          
        end
      end
    end
  end
end
