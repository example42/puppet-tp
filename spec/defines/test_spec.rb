require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','sysdig']

# Sample options and rendered templates to test upon
sample_options = {
  'host' => 'spec.example.com',
  'port' => '8080',
}
sample_erb = File.read(File.join(File.dirname(__FILE__), '../tpdata/sample.erb'))
sample_epp = File.read(File.join(File.dirname(__FILE__), '../tpdata/sample.epp'))

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
          'tag'     => 'tp_test',
        }

        # Resource counts with normal tp::test
        total_count = 16 # tp::test + file + tp
        package_count = 0
        service_count = 0
        exec_count = 0
        file_count = 15 # Includes files from tp

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
            it { is_expected.to compile.with_all_deps }
            it { should have_file_resource_count(file_count) }
            it { should have_resource_count(total_count) }
          end
          context 'with source => puppet:///modules/tp/spec' do
            let(:params) { { 'source' => 'puppet:///modules/tp/spec' } }
            it { is_expected.to contain_file("/etc/tp/test/#{app}").only_with(default_file_params.merge('source' => 'puppet:///modules/tp/spec')) }
          end
          context 'with template => tp/spec/sample.erb and sample my_options' do
            let(:params) do {
              'template'   => 'tp/spec/sample.erb',
              'my_options' => sample_options,
            } end
            it { is_expected.to contain_file("/etc/tp/test/#{app}").only_with(default_file_params.merge('content' => sample_erb)) }
          end
          context 'with template => tp/spec/sample.epp and sample my_options' do
            let(:params) do {
              'template'   => 'tp/spec/sample.epp',
              'my_options' => sample_options,
            } end
            it { is_expected.to contain_file("/etc/tp/test/#{app}").only_with(default_file_params.merge('content' => sample_epp)) }
          end
          context 'with epp => tp/spec/sample.epp and sample my_options' do
            let(:params) do {
              'epp'        => 'tp/spec/sample.epp',
              'my_options' => sample_options,
            } end
            it { is_expected.to contain_file("/etc/tp/test/#{app}").only_with(default_file_params.merge('content' => sample_epp)) }
          end
          context 'with content => sample' do
            let(:params) do {
              'content' => 'sample',
            } end
            it { is_expected.to contain_file("/etc/tp/test/#{app}").only_with(default_file_params.merge('content' => 'sample')) }
          end
          context 'with ensure => absent and source'  do
            let(:params) { { 'ensure' => 'absent' , 'source' => 'puppet:///modules/tp/spec' } }
            it { is_expected.to contain_file("/etc/tp/test/#{app}").with('ensure' => 'absent') }
          end
        end
      end
    end
  end
end
