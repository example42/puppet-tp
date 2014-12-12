require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tp::stdmod', :type => :define do
  let(:title) { 'redis' }

  context 'with title redis and default parameters' do
    let(:title) { 'redis' }
    it { should contain_package('redis').with_ensure('present') }
    it { should contain_service('redis').with_ensure('running') }
    it { should contain_service('redis').with_enable('true') }
  end

  context 'with title redis and package_name = redis-test' do
    let(:params) {
      {
        'package_name' => 'redis-test',
      }
    }
    it { should have_package_resource_count(1) }
    it { should contain_package('redis-test').with_ensure('present') }
    it { should contain_service('redis').with_ensure('running') }
    it { should contain_service('redis').with_enable('true') }
  end

  context 'with title redis and service_name = redis-test' do
    let(:params) {
      {
        'service_name' => 'redis-test'
      }
    }
    it { should have_service_resource_count(1) }
    it { should contain_package('redis').with_ensure('present') }
    it { should contain_service('redis-test').with_ensure('running') }
    it { should contain_service('redis-test').with_enable('true') }
  end

  context 'with title redis and custom erb template and options_hash' do
    let(:params) {
      {
        'config_file_template' => 'tp/spec/stdmod_spec.erb',
        'config_file_options_hash' => { 
          'key_a'  => 'value_a',
          'key_b'  => 'value_b',
        },
      }
    }
    it { should contain_package('redis').with_ensure('present') }
    it { should contain_service('redis').with_ensure('running') }
    it { should contain_service('redis').with_enable('true') }
    it { should have_file_resource_count(1) }
    it do
      should contain_file('/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis.conf',
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end
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

  context 'with title redis and custom settings on testos 0.0.1 operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1'
      }
    }
    let(:params) {
      {
        'service_name' => 'redis-test'
      }
    }
    it { should contain_package('redis-testos001').with_ensure('present') }
    it { should contain_service('redis-test').with_ensure('stopped') }
    it { should contain_service('redis-test').with_enable('false') }
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
    it { should contain_class('tp::spec::extra') }
    it { should contain_class('tp::spec::dependency') }
    it { should contain_class('tp::spec::monitor') }
    it { should contain_class('tp::spec::firewall') }
  end
end
