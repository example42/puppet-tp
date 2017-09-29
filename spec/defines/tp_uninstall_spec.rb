require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','openssh','elasticsearch','sysdig','puppet-agent']

describe 'tp::uninstall', :type => :define do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))

        # Default params
        default_package_params = {
          'ensure'  => 'absent',
        }
        default_service_params = {
          'ensure'  => 'stopped',
          'enable'  => false,
        }

        # Resource counts with normal tp::uninstall
        total_count = '1' # tp::uninstall
        package_count = '0'
        service_count = '0'
        exec_count = '0'
        file_count = '0'
        has_repo = false

        # Define if there's a service to check
        if appdata['service_name']
          has_service = true
          total_count = total_count.to_i + 1
          service_count = service_count.to_i + 1
        else
          has_service = false
        end
        # Evaluate packages presence
        if appdata['package_name']
          total_count = total_count.to_i + 1
          package_count = package_count.to_i + 1
        end
        # Added resources when repos are managed
        if appdata['repo_url'] or appdata['yum_mirrorlist'] 
          total_count = total_count.to_i + 1 # tp::repo
        end

        # Increment counters for resources in tp::repo
        if ( appdata['repo_url'] or appdata['yum_mirrorlist'] ) and os == 'centos-7-x86_64'
          total_count = total_count.to_i + 1 # yumrepo
        end
        if appdata['key'] and appdata['key_url'] and appdata['repo_url'] and os == 'ubuntu-16.04-x86_64'
          total_count = total_count.to_i + 1 # file $app.list
          file_count = file_count.to_i + 1   # file $app.list
        end
        if appdata['key'] and ( appdata['package_name'] and appdata['package_name'] !=0 ) and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-get update
          total_count = total_count.to_i + 1 # exec apt-get update
        end 
        if appdata['key'] and appdata['key_url'] and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-key add
          total_count = total_count.to_i + 1 # exec apt-key add
        end
        if appdata['key'] and appdata['apt_key_server'] and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-key adv --keyserver
          total_count = total_count.to_i + 1 # exec apt-key adv --keyserver
        end

        # Interate contexts over os and over app
        context "with app #{app}" do
          let(:title) { app }

          context 'without any param' do
            it { is_expected.to compile }
            # it { should have_tp__install_resource_count(1) }
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
          context 'with settings_hash => { package_name => custom , service_name => custom }' do
            custom_settings = {
              'package_name' => 'custom',
              'service_name' => 'custom',
            }
            let(:params) { { 'settings_hash' => custom_settings } }
            it { is_expected.to contain_package('custom').only_with(default_package_params) }
            if has_service
              it { is_expected.to contain_service('custom').only_with(default_service_params) }
            end
          end
          context 'with default settings should auto_repo if repo data is present' do
            if has_repo
              it { is_expected.to contain_tp__repo(app).with(repo_params) }
            end
          end
          context 'with auto_repo => false' do
            let(:params) { { 'auto_repo' => false } }
            it { should have_tp__repo_resource_count(0) }
          end
        end
      end
    end
  end
end
