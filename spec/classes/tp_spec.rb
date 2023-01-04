require 'spec_helper'

describe 'tp' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      file_resource_count = 15
      file_resource_count = file_resource_count if os == 'windows-2008 R2-x64' or os == 'windows-2012 R2-x64'
      file_resource_count = file_resource_count -1 if os == 'darwin-17'
      resource_count = file_resource_count + 0

      context 'with default params' do
        it { is_expected.to compile.with_all_deps }
        it { should have_file_resource_count(file_resource_count) }
        it { should have_resource_count(resource_count) }
      end

      context 'with identity privileged fact set to false' do
        let(:facts) { os_facts.merge({'identity' => {'privileged' => false}}) }
        it { is_expected.to compile.with_all_deps }
        it { should have_file_resource_count(0) }
        it { should have_resource_count(0) }
      end

      context 'when install_hash is an array' do
        let(:params) do
          {
            tp_owner: 'al',
            tp_group: 'al',
            install_hash: %w[openssh sysdig]
          }
        end

        it { is_expected.to contain_tp__install('openssh') }
        it { is_expected.to contain_tp__install('sysdig') }
      end

      context 'when install_hash is an hash' do
        let(:params) do
          {
            tp_owner: 'al',
            tp_group: 'al',
            install_hash: { 'openssh' => { 'ensure' => 'present' }, 'sysdig' => { 'ensure' => 'present' } }
          }
        end
        it { is_expected.to contain_tp__install('openssh') }
        it { is_expected.to contain_tp__install('sysdig') }
      end

      context 'with custom tp_owner =al, tp_group => al, purge_dirs => true' do
        let(:params) do
          {
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
        it { is_expected.to contain_file('/etc/tp').only_with(dir_params) } if os != 'windows-2008 R2-x64' and os != 'windows-2012 R2-x64'
        it { is_expected.to contain_file('C:/ProgramData/PuppetLabs/tp').only_with(dir_params) } if os == 'windows-2008 R2-x64' or os == 'windows-2012 R2-x64'
      end

    end
  end
end
