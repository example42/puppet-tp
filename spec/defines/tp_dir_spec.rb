require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','postfix']

describe 'tp::dir', :type => :define do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))
        context "application #{app}" do
          let(:title) { app }
          let(:pre_condition) { "tp::install { #{app}: }" }
          default_file_params = {
            'ensure'  => 'directory',
            'path'    => appdata['config_dir_path'],
            'mode'    => appdata['config_dir_mode'],
            'owner'   => appdata['config_dir_owner'],
            'group'   => appdata['config_dir_group'],
            'notify'  => "Service[#{appdata['service_name']}]",
            'require' => "Package[#{appdata['package_name']}]",
          }
          context 'without any param' do
            it { is_expected.to compile }
            it { should have_file_resource_count(1) }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params) }
          end
          context 'with ensure => absent' do
            let(:params) { { 'ensure' => 'absent' } }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params.merge('ensure' => 'absent')) }
          end
          context 'with title => /tmp/sample' do
            let(:title) { '/tmp/sample' }
            expected_path = '/tmp/sample'
            it { is_expected.to contain_file(expected_path).with('path' => expected_path) }
            it { is_expected.to contain_file(expected_path).without_notify }
            it { is_expected.to contain_file(expected_path).without_require }
          end
          context "with title => #{app}::sample and path => /tmp/sample" do
            let(:title) { "#{app}::sample" }
            let(:params) do {
              'path'      => '/tmp/sample',
            } end
            expected_path = '/tmp/sample'
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample and base_dir => data" do
            let(:title) { "#{app}::sample" }
            let(:params) do {
              'base_dir'      => 'data',
            } end
            expected_path = appdata['data_dir_path']
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample and base_dir => data and path => /tmp/sample" do
            let(:title) { "#{app}::sample" }
            let(:params) do {
              'base_dir'      => 'data',
              'path'      => '/tmp/sample.conf',
            } end
            expected_path = '/tmp/sample.conf'
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context 'with mode => 700' do
            let(:params) { { 'mode' => '700' } }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params.merge('mode' => '700')) }
          end
          context 'with owner => al' do
            let(:params) { { 'owner' => 'al' } }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params.merge('owner' => 'al')) }
          end
          context 'with group => al' do
            let(:params) { { 'group' => 'al' } }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params.merge('group' => 'al')) }
          end
          context 'with config_dir_notify => Service[alt]' do
            let(:pre_condition) { "tp::install { #{app}: }; service { alt: }" }
            let(:params) { { 'config_dir_notify' => 'Service[alt]' } }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params.merge('notify' => 'Service[alt]')) }
          end
          context 'with config_dir_notify => false' do
            let(:params) { { 'config_dir_notify' => false } }
            it { is_expected.to contain_file(appdata['config_dir_path']).without_notify }
          end
          context 'with config_dir_require => Package[alt]' do
            let(:pre_condition) { "tp::install { #{app}: }; package { alt: }" }
            let(:params) { { 'config_dir_require' => 'Package[alt]' } }
            it { is_expected.to contain_file(appdata['config_dir_path']).only_with(default_file_params.merge('require' => 'Package[alt]')) }
          end
          context 'with config_dir_require => false' do
            let(:params) { { 'config_dir_require' => false } }
            it { is_expected.to contain_file(appdata['config_dir_path']).without_require }
          end
          context 'with config_dir_notify => false and config_dir_require => false' do
            let(:params) do {
              'config_dir_notify'  => false,
              'config_dir_require' => false,
            } end
            it { is_expected.to contain_file(appdata['config_dir_path']).without_notify }
            it { is_expected.to contain_file(appdata['config_dir_path']).without_require }
          end
          context 'with settings_hash => { config_dir_path => /tmp/custom, config_dir_mode => 700 }' do
            custom_settings = {
              'config_dir_path' => '/tmp/custom',
              'config_dir_mode' => '700',
            }
            let(:params) { { 'settings_hash' => custom_settings } }
            it { is_expected.to contain_file('/tmp/custom').only_with(default_file_params.merge('path' => '/tmp/custom', 'mode' => '700')) }
          end
        end
      end
    end
  end
end
