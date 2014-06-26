require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tp::install', :type => :define do
  let(:title) { 'redis' }

  context 'with default parameters' do
    it do
      should contain_package('redis').with_ensure('present')
      should contain_service('redis').with_ensure('running')
      should contain_service('redis').with_enable('true')
    end
  end

  context 'with custom packages' do
    let(:params) {
      {
        'packages' => { 'redis' => { 'ensure' => 'absent' } }
      }
    }
    it do
      should have_package_resource_count(1)
      should contain_package('redis').with_ensure('absent')
    end
  end

  context 'with custom services' do
    let(:params) {
      {
        'services' => { 'redis' => { 'ensure' => 'stopped' } }
      }
    }
    it do
      should have_service_resource_count(1)
      should contain_package('redis').with_ensure('present')
      should contain_service('redis').with_ensure('stopped')
    end
  end

  context 'with test osfamily' do
    let(:facts) {
      {
        :osfamily => 'test',
      }
    }
    it do
      should contain_package('redis-test').with_ensure('present')
      should contain_service('redis-test').with_ensure('stopped')
      should contain_service('redis-test').with_enable('false')
    end
  end

  context 'with testos operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
      }
    }
    it do
      should contain_package('redis-testos').with_ensure('present')
      should contain_service('redis-testos').with_ensure('running')
      should contain_service('redis-testos').with_enable('true')
    end
  end

  context 'with testos 0.0.1 operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1'
      }
    }
    it do
      should contain_package('redis-testos001').with_ensure('present')
      should contain_service('redis-testos001').with_ensure('running')
      should contain_service('redis-testos001').with_enable('true')
    end
  end


  context 'with Debian osfamily on apache' do
    let(:title) { 'apache' }
    let(:facts) {
      {
        :osfamily => 'Debian',
      }
    }
    it do
      should contain_package('apache2').with_ensure('present')
      should contain_service('apache2').with_ensure('stopped')
      should contain_service('apache2').with_enable('false')
    end
  end


  context 'with custom classes' do
    let(:params) {
      {
        :extra_class      => 'tp::spec::extra',
        :dependency_class => 'tp::spec::dependency',
        :monitor_class    => 'tp::spec::monitor',
        :firewall_class   => 'tp::spec::firewall',
      }
    }
    it do
      should contain_class('tp::spec::extra')
      should contain_class('tp::spec::dependency')
      should contain_class('tp::spec::monitor')
      should contain_class('tp::spec::firewall')
    end
  end

end
