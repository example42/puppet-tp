require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tp::install', :type => :define do
  let(:title) { 'redis' }

  context 'with title redis and default parameters' do
    it { should contain_package('redis').with_ensure('present') }
    it { should contain_service('redis').with_ensure('running') }
    it { should contain_service('redis').with_enable('true') }
  end

  context 'with title redis and custom packages hash' do
    let(:params) {
      {
        'packages' => { 'my_redis' => { 'ensure' => 'absent' } }
      }
    }
    it { should have_package_resource_count(1) }
    it { should contain_package('my_redis').with_ensure('absent') }
  end

  context 'with title redis and custom services hash' do
    let(:params) {
      {
        'services' => { 'redis' => { 'ensure' => 'stopped' } }
      }
    }
    it { should have_service_resource_count(1) }
    it { should contain_package('redis').with_ensure('present') }
    it { should contain_service('redis').with_ensure('stopped') }
  end

  context 'with title redis and test osfamily' do
    let(:facts) {
      {
        :osfamily => 'test',
      }
    }
    it { should contain_package('redis-test').with_ensure('present') }
    it { should contain_service('redis-test').with_ensure('stopped') }
    it { should contain_service('redis-test').with_enable('false') }
  end

  context 'with title redis and testos operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
      }
    }
    it { should contain_package('redis-testos').with_ensure('present') }
    it { should contain_service('redis-testos').with_ensure('stopped') }
    it { should contain_service('redis-testos').with_enable('false') }
  end

  context 'with title redis and testos 0.0.1 operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1'
      }
    }
    it { should contain_package('redis-testos001').with_ensure('present') }
    it { should contain_service('redis-testos001').with_ensure('stopped') }
    it { should contain_service('redis-testos001').with_enable('false') } 
  end


  context 'with title redis and Debian osfamily on apache' do
    let(:title) { 'apache' }
    let(:facts) {
      {
        :osfamily => 'Debian',
      }
    }
    it { should contain_package('apache2').with_ensure('present') }
    it { should contain_service('apache2').with_ensure('running') }
    it { should contain_service('apache2').with_enable('true') }
  end


  context 'with title redis and custom classes' do
    let(:params) {
      {
        :extra_class      => 'tpdata::spec::extra',
        :dependency_class => 'tpdata::spec::dependency',
        :monitor_class    => 'tpdata::spec::monitor',
        :firewall_class   => 'tpdata::spec::firewall',
      }
    }
    it { should contain_class('tpdata::spec::extra') }
    it { should contain_class('tpdata::spec::dependency') }
    it { should contain_class('tpdata::spec::monitor') }
    it { should contain_class('tpdata::spec::firewall') }
  end

end
