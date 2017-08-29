require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','openssh','elasticsearch','sysdig','puppet-agent']

describe 'tp::install', :type => :define do
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
          'require' => "Package[#{appdata['package_name']}]",
        }

        # Resource counts with normal tp::install + package + service
        total_count = 3
        package_count = 1
        service_count = 1
        exec_count = 0
        file_count = 0
        has_repo = false

        # Define if there's a service to check
        if appdata['service_name']
          has_service = true
        else
          has_service = false
          total_count = total_count.to_i - 1
          service_count = service_count.to_i - 1
        end
        # Added resources when repos are managed
        if appdata['repo_url'] or appdata['yum_mirrorlist'] or appdata['repo_package_url']
          has_repo = true
          total_count = total_count.to_i + 1 # tp::repo
          repo_params = {
            'enabled'       => true,
            'before'        => "Package[#{appdata['package_name']}]",
            'data_module'   => 'tinydata',
            'settings_hash' => {},
            'description'   => "#{app} repository",
            'include_src'   => false,
            'debug'         => false,
            'debug_dir'     => '/tmp',
          }
        end

        # Increment package count if repo_package_url and repo_package_name are present
        if appdata['repo_package_url'] and appdata['repo_package_name']
          package_count = package_count.to_i + 1
          total_count = total_count.to_i + 1
        end
        # Increment counters for resources in tp::repo
        if ( appdata['repo_url'] or appdata['yum_mirrorlist'] ) and os == 'centos-7-x86_64'
          total_count = total_count.to_i + 1 # yumrepo
        end
        if appdata['repo_url'] and appdata['apt_release'] and os == 'ubuntu-16.04-x86_64'
        # if appdata['repo_url'] and appdata['apt_release'] and appdata['apt_repos'] and os == 'ubuntu-16.04-x86_64'
          total_count = total_count.to_i + 1 # file $app.list
          file_count = file_count.to_i + 1   # file $app.list
        end
        if appdata['repo_url'] and ( appdata['package_name'] and appdata['package_name'] !=0 ) and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-get update
          total_count = total_count.to_i + 1 # exec apt-get update
        end 
        if appdata['repo_url'] and appdata['key'] and appdata['key_url'] and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-key add
          total_count = total_count.to_i + 1
        end 
        if appdata['repo_url'] and appdata['key'] and appdata['apt_key_server'] and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-key adv --keyserver
          total_count = total_count.to_i + 1
        end 

        # Interate contexts over os and over app
        context "with app #{app}" do
          let(:title) { app }

          context 'without any param' do
            it { is_expected.to compile }
            # it { should have_tp__install_resource_count(1) }
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
          context 'with ensure => absent' do
            let(:params) { { 'ensure' => 'absent' } }
            it { is_expected.to contain_package(appdata['package_name']).only_with(default_package_params.merge('ensure' => 'absent')) }
            if has_service
              it { is_expected.to contain_service(appdata['service_name']).only_with(default_service_params.merge('ensure' => 'stopped', 'enable' => false)) }
            end
          end
          context 'with settings_hash => { package_name => custom , service_name => custom }' do
            custom_settings = {
              'package_name' => 'custom',
              'service_name' => 'custom',
            }
            let(:params) { { 'settings_hash' => custom_settings } }
            it { is_expected.to contain_package('custom').only_with(default_package_params) }
            if has_service
              it { is_expected.to contain_service('custom').only_with(default_service_params.merge('require' => 'Package[custom]')) }
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
          context 'with auto_prereq => true' do
            let(:params) { { 'auto_prereq' => true } }
            if appdata['package_prerequisites']
              it { is_expected.to contain_package(appdata['package_prerequisites']).with('ensure' => 'present') }
            end
            if appdata['tp_prerequisites']
              appdata['tp_prerequisites'].each do |tp_pre|
                it { is_expected.to contain_tp__install(tp_pre) }
              end
            end
            if appdata['exec_prerequisites']
              it { is_expected.to contain_exec(appdata['exec_prerequisites']) }
            end
            if appdata['exec_postinstall']
              it { is_expected.to contain_exec(appdata['exec_postinstall']) }
            end
          end
        end
      end
    end
  end
end
