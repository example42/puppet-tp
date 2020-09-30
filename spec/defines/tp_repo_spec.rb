require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','openssh','elasticsearch','sysdig','icinga2']

describe 'tp::repo', :type => :define do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))

        # Resource counts with normal tp::repo
        total_count = 1
        package_count = 0
        service_count = 0
        exec_count = 0
        file_count = 0

        # Increment exec counters on Ubuntu
        if os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-get update
          total_count = total_count.to_i + 1 # exec apt-get update
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
        if appdata['repo_url'] and appdata['apt_release'] and appdata['apt_repos'] and os == 'ubuntu-16.04-x86_64'
          total_count = total_count.to_i + 1 # file $app.list
          file_count = file_count.to_i + 1   # file $app.list
        end
        if appdata['repo_url'] and appdata['key'] and appdata['key_url'] and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-key add
          file_count = file_count.to_i + 1   # file $app.list
          total_count = total_count.to_i + 2
        end 
        if appdata['repo_url'] and appdata['key'] and appdata['apt_key_server'] and appdata['apt_key_fingerprint'] and os == 'ubuntu-16.04-x86_64'
          exec_count = exec_count.to_i + 1   # exec apt-key adv --keyserver
          total_count = total_count.to_i + 1
        end

        # Interate contexts over os and over app
        context "with app #{app}" do
          let(:title) { app }
          # Add tp::install resources
          let(:pre_condition) { "tp::install { #{app}: auto_repo => false }" }
          total_count = total_count.to_i + 1 # tp::install
          if appdata['package_name']
            package_count = package_count.to_i + 1   # package
            total_count = total_count.to_i + 1
          end
          if appdata['service_name']
            service_count = service_count.to_i + 1   # servicee
            total_count = total_count.to_i + 1
          end
          context 'without any param' do
            it { is_expected.to compile }
            it { should have_tp__repo_resource_count(1) }
            it { should have_package_resource_count(package_count) }
            it { should have_exec_resource_count(exec_count) }
            it { should have_file_resource_count(file_count) }
            it { should have_resource_count(total_count) }
          end
          context 'with debug => true and debug_dir => /var/tmp' do
            let(:params) do {
              'debug'     => true,
              'debug_dir' => '/var/tmp',
            } end
            it { is_expected.to contain_file("tp_repo_debug_#{app}").with('ensure' => 'present', 'path' => "/var/tmp/tp_repo_debug_#{app}") }
          end

          context 'with exec_environment set' do
            let(:params) do {
              'exec_environment' => ['http_proxy=http://proxy.domain:8080','https_proxy=http://proxy.domain:8080'],
            } end
            if appdata['repo_package_url'] and appdata['repo_package_name'] and os == 'ubuntu-16.04-x86_64'
              it { is_expected.to contain_exec("Download #{app} release package").with('environment' => ['http_proxy=http://proxy.domain:8080','https_proxy=http://proxy.domain:8080']) }
            end
            if appdata['key'] or appdata['key_url'] and os == 'ubuntu-16.04-x86_64'
              it { is_expected.to contain_exec("tp_aptkey_add_#{appdata['key']}").with('environment' => ['http_proxy=http://proxy.domain:8080','https_proxy=http://proxy.domain:8080']) }
            end
            if appdata['key'] and appdata['apt_key_fingerprint'] and appdata['apt_key_server'] and os == 'ubuntu-16.04-x86_64'
              it { is_expected.to contain_exec("tp_aptkey_adv_#{appdata['key']}").with('environment' => ['http_proxy=http://proxy.domain:8080','https_proxy=http://proxy.domain:8080']) }
            end
          end
        end
      end
    end
  end
end
