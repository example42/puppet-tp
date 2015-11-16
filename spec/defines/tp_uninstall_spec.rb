if ENV['PARSER'] == 'future'
  require 'spec_helper'
  
  describe 'tp::uninstall', :type => :define do
    let(:title) { 'redis' }
  
    context 'with title redis and default parameters' do
      it { should contain_package('redis').with_ensure('absent') }
      it { should contain_service('redis').with_ensure('stopped') }
      it { should contain_service('redis').with_enable('false') }
    end
  
    context 'with title redis and custom package name' do
      let(:params) {
        {
          'settings_hash' => { 'package_name' => 'my_redis' }
        }
      }
      it { should have_package_resource_count(1) }
      it { should contain_package('my_redis').with_ensure('absent') }
    end
  
    context 'with title apache on Debian osfamily' do
      let(:title) { 'apache' }
      let(:facts) {
        {
          :osfamily => 'Debian',
        }
      }
      it { should contain_package('apache2').with_ensure('absent') }
      it { should contain_service('apache2').with_ensure('stopped') }
      it { should contain_service('apache2').with_enable('false') }
    end
  
  end
end
