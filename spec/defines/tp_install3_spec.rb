require 'spec_helper'

describe 'tp::install3', :type => :define do
  let(:title) { 'redis' }

  context 'with title redis and default parameters' do
    it { should contain_package('redis').with_ensure('present') }
    it { should contain_service('redis').with_ensure('running') }
    it { should contain_service('redis').with_enable('true') }
  end

  context 'with title redis and custom package name' do
    let(:params) {
      {
        'settings_hash' => { 'package_name' => 'my_redis' }
      }
    }
    it { should have_package_resource_count(1) }
    it { should contain_package('my_redis').with_ensure('present') }
  end

  context 'with title redis and stopped service' do
    let(:params) {
      {
        'settings_hash' => { 'service_ensure' => 'stopped' }
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


  context 'with custom classes' do
    let(:params) {
      {
        :dependency_class => 'tp::spec::dependency',
        :monitor_class    => 'tp::spec::monitor',
        :firewall_class   => 'tp::spec::firewall',
      }
    }
    it { should contain_class('tp::spec::dependency') }
    it { should contain_class('tp::spec::monitor') }
    it { should contain_class('tp::spec::firewall') }
  end


  context 'with title redis and auto_conf set to true' do
    let(:facts) {
      {
        :osfamily => 'test',
      }
    }
    let(:params) {
      {
        'auto_conf' => true,
      }
    }
    it { should contain_file('/etc/redis-test/redis.conf').with_ensure('present') }
    it { should contain_file('/etc/sysconfig/redis-test').with_ensure('present') }
  end

  context 'with title redis and auto_conf set to false' do
    let(:facts) {
      {
        :osfamily => 'test',
      }
    }
    let(:params) {
      {
        'auto_conf' => false,
      }
    }
    it { should_not contain_file('/etc/redis-test/redis.conf').with_ensure('present') }
    it { should_not contain_file('/etc/sysconfig/redis-test').with_ensure('present') }
  end

  context 'with title redis and auto_conf not set (default)' do
    let(:facts) {
      {
        :osfamily => 'test',
      }
    }
    it { should contain_file('/etc/redis-test/redis.conf').with_ensure('present') }
    it { should contain_file('/etc/sysconfig/redis-test').with_ensure('present') }
  end
end
