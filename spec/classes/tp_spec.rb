require 'spec_helper'

describe 'tp' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      file_resource_count = 4
      file_resource_count = file_resource_count + 1 if os == 'windows-2008 R2-x64' or os == 'windows-2012 R2-x64'

      context 'with default params' do
        it { is_expected.to compile }
        it { should have_file_resource_count(file_resource_count) }
        it { should have_resource_count(file_resource_count) }
      end

      context 'when install_hash is an array' do
        let(:params) do
          {
            tp_dir: '/opt/tp',
            tp_owner: 'al',
            tp_group: 'al',
            tp_path: '/usr/bin/tp',
            install_hash: %w[openssh sysdig]
          }
        end

        it { is_expected.to contain_tp__install('openssh') }
        it { is_expected.to contain_tp__install('sysdig') }
      end

      context 'when install_hash is an hash' do
        let(:params) do
          {
            tp_dir: '/opt/tp',
            tp_owner: 'al',
            tp_group: 'al',
            tp_path: '/usr/bin/tp',
            install_hash: { 'openssh' => { 'ensure' => 'present' }, 'sysdig' => { 'ensure' => 'present' } }
          }
        end
        it { is_expected.to contain_tp__install('openssh') }
        it { is_expected.to contain_tp__install('sysdig') }
      end

      context 'with custom tp_dir => /opt/tp, tp_owner =al, tp_group => al, tp_path => /usr/bin/tp' do
        let(:params) do
          {
            'tp_dir' => '/opt/tp',
            'tp_owner' => 'al',
            'tp_group' => 'al',
            'tp_path'  => '/usr/bin/tp'
          }
        end

        dir_params = {
          'ensure'  => 'directory',
          'mode'    => '0755',
          'owner'   => 'al',
          'group'   => 'al',
          'purge'   => false,
          'force'   => false,
          'recurse' => false,
        }
        file_params = {
          'ensure' => 'present',
          'mode'   => '0755',
          'owner'  => 'al',
          'group'  => 'al',
          'path'   => '/usr/bin/tp'
        }
        it { is_expected.to contain_file('/opt/tp').only_with(dir_params) }
        it { is_expected.to contain_file('/usr/bin/tp').with(file_params) }
      end

      context 'with custom tp_dir => /opt/tp, tp_owner =al, tp_group => al, purge_dirs => true' do
        let(:params) do
          {
            'tp_dir'     => '/opt/tp',
            'tp_owner'   => 'al',
            'tp_group'   => 'al',
            'purge_dirs' => true,
          } 
        end
        
        dir_params = {
          'ensure'  => 'directory',
          'mode'    => '0755',
          'owner'   => 'al',
          'group'   => 'al',
          'purge'   => true,
          'force'   => true,
          'recurse' => true,
        } 
        it { is_expected.to contain_file('/opt/tp').only_with(dir_params) }
      end

    end
  end
end
