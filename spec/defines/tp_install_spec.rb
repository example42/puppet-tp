require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tp::install', :type => :define do
  let(:title) { 'redis' }
  let(:facts) { {:osfamily => 'Darwin', :operatingsystem => 'Darwin', :operatingsystemrelease => '13.2.0'} }

  context 'with default parameters' do
    it do
      should contain_package('redis').with_ensure('present')
      should contain_service('redis').with_ensure('running')
      should contain_service('redis').with_enable('true')
    end
  end

  context 'parametrized' do
    let(:params) {
      {
        'packages' => { 'redis' => { 'ensure' => 'absent' } }
      }
    }
    it do
      should contain_package('redis').with_ensure('absent')
    end
  end
end
