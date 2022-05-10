require 'spec_helper'

# Apps to test against. Data is in spec/tpdata/
apps = ['rsyslog','postfix']

# Sample options and rendered templates to test upon
sample_options = {
  'host' => 'spec.example.com',
  'port' => '8080',
}
sample_erb = File.read(File.join(File.dirname(__FILE__), '../tpdata/sample.erb'))
sample_epp = File.read(File.join(File.dirname(__FILE__), '../tpdata/sample.epp'))

describe 'tp::conf', :type => :define do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))
        context "wiht app #{app}" do
          let(:title) { app }
          let(:pre_condition) { "tp::install { #{app}: }" }
          default_file_params = {
            'ensure'  => 'present',
            'path'    => appdata['config_file_path'],
            'mode'    => appdata['config_file_mode'],
            'owner'   => appdata['config_file_owner'],
            'group'   => appdata['config_file_group'],
            'notify'  => "Service[#{appdata['service_name']}]",
            'require' => "Package[#{appdata['package_name']}]",
          }
          context 'without any param' do
            it { is_expected.to compile }
            it { should have_file_resource_count(1) }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params) }
          end
          context 'with ensure => absent' do
            let(:params) { { 'ensure' => 'absent' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('ensure' => 'absent')) }
          end
          context 'with source => puppet:///modules/tp/spec' do
            let(:params) { { 'source' => 'puppet:///modules/tp/spec' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('source' => 'puppet:///modules/tp/spec')) }
          end
          context 'with template => tp/spec/sample.erb and sample options_hash' do
            let(:params) do {
              'template'     => 'tp/spec/sample.erb',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => sample_erb)) }
          end
          context 'with template => tp/spec/sample.epp and sample options_hash' do
            let(:params) do {
              'template'     => 'tp/spec/sample.epp',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => sample_epp)) }
          end
          context 'with epp => tp/spec/sample.epp and sample options_hash' do
            let(:params) do {
              'epp'          => 'tp/spec/sample.epp',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => sample_epp)) }
          end
          context 'with content => sampletext' do
            let(:params) do {
              'content'      => 'sampletext',
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => 'sampletext')) }
          end
          context 'with content => sampletext and template => tp/spec/sample.erb' do
            let(:params) do {
              'content'      => 'sampletext',
              'template'     => 'tp/spec/sample.erb',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => 'sampletext')) }
          end
          context 'with content => sampletext and epp => tp/spec/sample.epp' do
            let(:params) do {
              'content'      => 'sampletext',
              'epp'          => 'tp/spec/sample.epp',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => 'sampletext')) }
          end
          context 'with content => sampletext, template => tp/spec/sample.erb and epp => tp/spec/sample.epp' do
            let(:params) do {
              'content'      => 'sampletext',
              'template'     => 'tp/spec/sample.erb',
              'epp'          => 'tp/spec/sample.epp',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => 'sampletext')) }
          end
          context 'with template => tp/spec/sample.erb and epp => tp/spec/sample.epp' do
            let(:params) do {
              'template'     => 'tp/spec/sample.erb',
              'epp'          => 'tp/spec/sample.epp',
              'options_hash' => sample_options,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('content' => sample_erb)) }
          end
          context "with title => #{app}::sample.conf" do
            let(:title) { "#{app}::sample.conf" }
            expected_path = "#{appdata['config_dir_path']}/sample.conf"
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample.conf and path => /tmp/sample.conf" do
            let(:title) { "#{app}::sample.conf" }
            let(:params) do {
              'path'      => '/tmp/sample.conf',
            } end
            expected_path = '/tmp/sample.conf'
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with base_file => init" do
            let(:params) do {
              'base_file'     => 'init',
            } end
            expected_path = appdata['init_file_path']
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample.conf and base_file => init" do
            let(:title) { "#{app}::sample.conf" }
            let(:params) do {
              'base_file'     => 'init',
            } end
            expected_path = appdata['init_file_path']
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample.conf and base_dir => data" do
            let(:title) { "#{app}::sample.conf" }
            let(:params) do {
              'base_dir'      => 'data',
            } end
            expected_path = "#{appdata['data_dir_path']}/sample.conf"
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample.conf and base_dir => data and base_file => init" do
            let(:title) { "#{app}::sample.conf" }
            let(:params) do {
              'base_dir'      => 'data',
              'base_file'     => 'init',
            } end
            expected_path = appdata['init_file_path']
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context "with title => #{app}::sample.conf and base_dir => data and base_file => init and path => /tmp/sample.conf" do
            let(:title) { "#{app}::sample.conf" }
            let(:params) do {
              'base_dir'      => 'data',
              'base_file'     => 'init',
              'path'      => '/tmp/sample.conf',
            } end
            expected_path = '/tmp/sample.conf'
            it { is_expected.to contain_file(expected_path).only_with(default_file_params.merge('path' => expected_path)) }
          end
          context 'with mode => 700' do
            let(:params) { { 'mode' => '700' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('mode' => '700')) }
          end
          context 'with owner => al' do
            let(:params) { { 'owner' => 'al' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('owner' => 'al')) }
          end
          context 'with group => al' do
            let(:params) { { 'group' => 'al' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('group' => 'al')) }
          end
          context 'with config_file_notify => Service[alt]' do
            let(:pre_condition) { "tp::install { #{app}: }; service { alt: }" }
            let(:params) { { 'config_file_notify' => 'Service[alt]' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('notify' => 'Service[alt]')) }
          end
          context 'with config_file_notify => false' do
            let(:params) { { 'config_file_notify' => false } }
            it { is_expected.to contain_file(appdata['config_file_path']).without_notify }
          end
          context 'with config_file_require => Package[alt]' do
            let(:pre_condition) { "tp::install { #{app}: }; package { alt: }" }
            let(:params) { { 'config_file_require' => 'Package[alt]' } }
            it { is_expected.to contain_file(appdata['config_file_path']).only_with(default_file_params.merge('require' => 'Package[alt]')) }
          end
          context 'with config_file_require => false' do
            let(:params) { { 'config_file_require' => false } }
            it { is_expected.to contain_file(appdata['config_file_path']).without_require }
          end
          context 'with config_file_notify => false and config_file_require => false' do
            let(:params) do {
              'config_file_notify'  => false,
              'config_file_require' => false,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).without_notify }
            it { is_expected.to contain_file(appdata['config_file_path']).without_require }
          end
          context 'with settings_hash => { config_file_path => /tmp/custom.conf, config_file_mode => 700 }' do
            custom_settings = {
              'config_file_path' => '/tmp/custom.conf',
              'config_file_mode' => '700',
            }
            let(:params) { { 'settings_hash' => custom_settings } }
            it { is_expected.to contain_file('/tmp/custom.conf').only_with(default_file_params.merge('path' => '/tmp/custom.conf', 'mode' => '700')) }
          end
          context 'with debug => true and debug_dir => /var/tmp' do
            let(:params) do {
              'debug'     => true,
              'debug_dir' => '/var/tmp',
            } end
            it { is_expected.to contain_file("tp_conf_debug_#{app}").with('ensure' => 'present', 'path' => "/var/tmp/tp_conf_debug_#{app}") }
          end
          context 'with validate_syntax => false' do
            let(:params) do {
              'validate_syntax' => false,
            } end
            it { is_expected.to contain_file(appdata['config_file_path']).without_validate_cmd }
          end
        end
      end
    end
  end
end
