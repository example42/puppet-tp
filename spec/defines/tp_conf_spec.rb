require 'spec_helper'

describe 'tp::conf', :type => :define do

  context 'with redis defaults' do
    let :title do
      'redis'
    end
    it { should compile }
    it { should have_file_resource_count(1) }
    it { should contain_file("/etc/redis/redis.conf") } 
    it do
      should contain_file('/etc/redis/redis.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis/redis.conf',
        'mode'    => '0644',
        'owner'   => 'root',
        'group'   => 'root',
      })
    end
  end

  context 'with redis defaults on test osfamily' do
    let :title do
      'redis'
    end

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
    let :title do
      'redis'
    end

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
    let :title do
      'redis'
    end

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


  context 'with user defined parameters' do
    let :title do
      'redis'
    end

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


  context 'with custom parameters on testos 0.0.1 operatingsystem' do
    let :title do
      'redis'
    end

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


  context 'with custom content (and *ignored* template, source and epp params)' do
    let :title do
      'redis'
    end

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


  context 'with custom erb template and options_hash' do
    let :title do
      'redis'
    end

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


  pending 'with custom epp template and options_hash' do
    let :title do
      'redis'
    end

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



  let :title do
    'redis::redis2.conf'
  end
  context 'with file specified in title' do
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


  context 'with file specified in title on test osfamily' do
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


  context 'with file specified in title on testos operatingsystem' do
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


  context 'with file specified in title on testos 0.0.1 operatingsystem' do
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

  context 'with path explicitly set' do
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


  context 'with custom parameters and forced path' do
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


  context 'with custom parameters on testos 0.0.1 operatingsystem' do
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


  context 'with custom content (and *ignored* template, source and epp params)' do
    let(:params) {
      {
        'content'      => "custom content",
        'epp'          => 'tp/spec/spec.epp',
        'template'     => 'tp/spec/spec.erb',
        'source'       => 'puppet:///modules/site/redis/redis2.conf',
      }
    }
    it do 
      should contain_file('/etc/redis/redis2.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis2.conf',             
        'content' => 'custom content',
      })                                                  
    end                                                   
  end 


  context 'with custom erb template and options_hash' do
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
      should contain_file('/etc/redis/redis2.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis2.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
  end 


  pending 'with custom epp template and options_hash' do
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
      should contain_file('/etc/redis/redis2.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis2.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
  end 

end
