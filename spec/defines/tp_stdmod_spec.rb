require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tp::stdmod', :type => :define do
  let(:title) { 'redis' }

  pending 'with default parameters' do
    it do
      should contain_package('redis').with_ensure('present')
      should contain_service('redis').with_ensure('running')
      should contain_service('redis').with_enable('true')
    end
  end

  pending 'with custom packages' do
    let(:params) {
      {
        'package_name' => 'redis-test',
      }
    }
    it do
      should have_package_resource_count(1)
      should contain_package('redis-test').with_ensure('present')
    end
  end

  pending 'with custom services' do
    let(:params) {
      {
        'service_name' => 'redis-test'
      }
    }
    it do
      should have_service_resource_count(1)
      should contain_package('redis').with_ensure('present')
      should contain_service('redis-test').with_ensure('running')
    end
  end

  pending 'with custom erb template and options_hash' do
    let(:params) {
      {
        'config_file_path' => '/etc/redis/redis-test.conf',
        'config_file_template' => 'tp/spec/spec.erb',
        'config_file_options_hash' => { 
          'key_a'  => 'value_a',
          'key_b'  => 'value_b',
        },
      }
    }
    it do
      should have_file_resource_count(1)
      should contain_file('tp_conf_/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis-test.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end
  end

  pending 'with test osfamily' do
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

  pending 'with testos operatingsystem' do
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

  pending 'custom settings on testos 0.0.1 operatingsystem' do
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
    it do
      should contain_package('redis-testos001').with_ensure('present')
      should contain_service('redis-test').with_ensure('running')
      should contain_service('redis-test').with_enable('true')
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
