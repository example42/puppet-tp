require 'spec_helper'

describe 'tp' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default params' do
        it { is_expected.to compile }
        it { should have_file_resource_count(4) }
        it { should have_resource_count(4) }
      end

      context 'with custom tp_dir => /opt/tp, tp_owner =al, tp_group => al, tp_path => /usr/bin/tp' do
        let(:params) do {
          'tp_dir'   => '/opt/tp',
          'tp_owner' => 'al',
          'tp_group' => 'al',
          'tp_path'  => '/usr/bin/tp',
        } end

        dir_params = {
          'ensure' => 'directory',
          'mode'   => '0755',
          'owner'  => 'al',
          'group'  => 'al',
        }
        file_params = {
          'ensure' => 'present',
          'mode'   => '0755',
          'owner'  => 'al',
          'group'  => 'al',
          'path'   => '/usr/bin/tp',
        }
        it { is_expected.to contain_file('/opt/tp').only_with(dir_params) }
        it { is_expected.to contain_file('/usr/bin/tp').with(file_params) }
      end
    end
  end
end
