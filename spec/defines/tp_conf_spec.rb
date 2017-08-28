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
        context "application #{app}" do
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
          skip 'with epp => tp/spec/sample.epp and sample options_hash' do
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
        end
      end
    end
  end
end
