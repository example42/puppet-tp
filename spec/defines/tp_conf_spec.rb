require 'spec_helper'

describe 'tp::conf', :type => :define do

  context 'with redis defaults' do
    let(:title) { 'redis' }
#    it { should compile }
    it { should have_file_resource_count(1) }
    it { should contain_file("/etc/redis/redis.conf") } 
    it do
      should contain_file('/etc/redis/redis.conf').with({
        'ensure'    => 'present',
        'path'      => '/etc/redis/redis.conf',
        'mode'      => '0644',
        'owner'     => 'root',
        'group'     => 'root',
      })
    end
  end

  context 'with redis defaults on test osfamily' do
    let(:title) { 'redis' }
    let(:facts) {
      {
        :osfamily => 'test',
      } 
    }
    it { should contain_file("/etc/redis-test/redis.conf") } 
    it do
      should contain_file('/etc/redis-test/redis.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-test/redis.conf',
        'mode'    => '0644',
        'owner'   => 'test',
        'group'   => 'test',
      })
    end
  end

  context 'with redis defaults on testos operatingsystem' do
    let(:title) { 'redis' }
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
      } 
    }
    it { should contain_file("/etc/redis-testos/redis.conf") } 
    it do
      should contain_file('/etc/redis-testos/redis.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-testos/redis.conf',
        'mode'    => '0644',
        'owner'   => 'test',
        'group'   => 'test',
      })
    end
  end

  context 'with redis defaults on testos 0.0.1 operatingsystemrelease' do
    let(:title) { 'redis' }
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1',
      } 
    }

    it { should contain_file("/etc/redis-testos001/redis.conf") } 
    it do
      should contain_file('/etc/redis-testos001/redis.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-testos001/redis.conf',
        'mode'    => '0644',
        'owner'   => 'test',
        'group'   => 'test',
      })
    end
  end


  context 'with title redis and custom source, path and permissions' do
    let(:title) { 'redis' }
    let(:params) {
      {
        'source' => 'puppet:///modules/site/redis/redis.conf',
        'path'   => '/opt/etc/redis/redis.conf',
        'mode'   => '0777',
        'owner'  => 'mytest',
        'group'  => 'mytest',
      }
    }
    it do
      should contain_file('/opt/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/opt/etc/redis/redis.conf',             
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
      })                                                  
    end                                                   
  end 


  context 'with title redis and custom parameters on testos 0.0.1 operatingsystem' do
    let(:title) { 'redis' }
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1',
      } 
    }
    let(:params) {
      { 
        'source' => 'puppet:///modules/site/redis/redis.conf',
        'mode'   => '0777',
        'owner'  => 'mytest',
        'group'  => 'mytest',
      }
    }
    it do
      should contain_file('/etc/redis-testos001/redis.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-testos001/redis.conf',
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
      })
    end
  end


  context 'with title redis and custom content (and *ignored* template, source and epp params)' do
    let(:title) { 'redis' }
    let(:params) {
      {
        'content'      => "custom content",
        'epp'          => 'tp/spec/spec.epp',
        'template'     => 'tp/spec/spec.erb',
        'source'       => 'puppet:///modules/site/redis/redis.conf',
      }
    }
    it do 
      should contain_file('/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis.conf',             
        'content' => 'custom content',
      })                                                  
    end                                                   
  end 


  context 'with title redis and custom erb template and options_hash' do
    let(:title) { 'redis' }
    let(:params) {
      {
        'template'     => 'tp/spec/spec.erb',
        'options_hash' => { 
          'key_a'  => 'value_a',
          'key_b'  => 'value_b',
        },
      }
    }
    it do 
      should contain_file('/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
  end 


  skip 'with custom epp template and options_hash' do
    let(:title) { 'redis' }
    let(:params) {
      {
        'epp'          => 'tp/spec/spec.epp',
        'options_hash' => { 
          'key_a'  => 'value_a',
          'key_b'  => 'value_b',
        },
      }
    }
    it do 
      should contain_file('/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
  end 

  context 'with title redis::redis2.conf' do
    let(:title) { 'redis::redis2.conf' }
    it do
      should contain_file('/etc/redis/redis2.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis/redis2.conf',
        'mode'    => '0644',
        'owner'   => 'root',
        'group'   => 'root',
      })
    end
  end


  context 'with title redis::redis2.conf on test osfamily' do
    let(:title) { 'redis::redis2.conf' }
    let :title do
      'redis::redis2.conf'
    end

    let(:facts) {
      {
        :osfamily => 'test',
      } 
    }
    it do
      should contain_file('/etc/redis-test/redis2.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-test/redis2.conf',
        'mode'    => '0644',
        'owner'   => 'test',
        'group'   => 'test',
      })
    end
  end


  context 'with title redis and file specified in title on testos operatingsystem' do
    let(:title) { 'redis::redis2.conf' }
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
      } 
    }
    it do
      should contain_file('/etc/redis-testos/redis2.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-testos/redis2.conf',
        'mode'    => '0644',
        'owner'   => 'test',
        'group'   => 'test',
      })
    end
  end


  context 'with title redis::redis2.conf on testos 0.0.1 operatingsystem' do
    let(:title) { 'redis::redis2.conf' }
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1',
      } 
    }
    it do
      should contain_file('/etc/redis-testos001/redis2.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-testos001/redis2.conf',
        'mode'    => '0644',
        'owner'   => 'test',
        'group'   => 'test',
      })
    end
  end

  context 'with title redis and path explicitly set' do
    let(:title) { 'redis' }
    let(:params) {
      {
        'path'   => '/opt/etc/redis/redis.conf',
      }
    }
    it do
      should contain_file('/opt/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/opt/etc/redis/redis.conf',             
      })                                                  
    end                                                   
  end 


  context 'with title redis and custom parameters and forced path' do
    let(:title) { 'redis' }
    let(:params) {
      {
        'source' => 'puppet:///modules/site/redis/redis2.conf',
        'path'   => '/opt/etc/redis/redis2.conf',
        'mode'   => '0777',
        'owner'  => 'mytest',
        'group'  => 'mytest',
      }
    }
    it do
      should contain_file('/opt/etc/redis/redis2.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/opt/etc/redis/redis2.conf',             
        'source'  => 'puppet:///modules/site/redis/redis2.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
      })                                                  
    end                                                   
  end 


  context 'with title redis::redis2.conf and custom parameters on testos 0.0.1 operatingsystem' do
    let(:title) { 'redis::redis2.conf' }
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1',
      } 
    }
    let(:params) {
      { 
        'source' => 'puppet:///modules/site/redis/redis2.conf',
        'mode'   => '0777',
        'owner'  => 'mytest',
        'group'  => 'mytest',
      }
    }
    it do
      should contain_file('/etc/redis-testos001/redis2.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis-testos001/redis2.conf',
        'source'  => 'puppet:///modules/site/redis/redis2.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
      })
    end
  end


  context 'with title redis and custom depedencies' do
    let(:title) { 'redis' }
    let(:params) { { 
      'config_file_require'  => 'Class[test]',
      'config_file_notify'  => 'Service[test]',
    } }
    it do
      should contain_file("/etc/redis/redis.conf").only_with ({
        'ensure'  => 'present',
        'path'    => '/etc/redis/redis.conf',
        'mode'    => '0644',
        'owner'   => 'root',
        'group'   => 'root',
        'notify'  => 'Service[test]',
        'require' => 'Class[test]',
      })
    end 
  end

  skip 'with custom epp template and options_hash' do
    let(:title) { 'redis' }
    let(:params) { {
      'epp'          => 'tp/spec/spec.epp',
      'options_hash' => { 
        'key_a'  => 'value_a',
        'key_b'  => 'value_b',
        },
      } }
    it do 
      should contain_file('/etc/redis/redis2.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis2.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
  end 
end
