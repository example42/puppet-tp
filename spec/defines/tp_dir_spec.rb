require 'spec_helper'

describe 'tp::dir', :type => :define do

  let :title do
    'redis'
  end
  context 'with default parameters' do
    it do
      should contain_file('tp_dir_/etc/redis').only_with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis',
        'mode'    => '0755',
        'owner'   => 'root',
        'group'   => 'root',
        'notify'  => 'Service[redis]',
      })
    end
  end


  context 'with default parameters on test osfamily' do
    let(:facts) {
      {
        :osfamily => 'test',
      } 
    }
    it do
      should contain_file('tp_dir_/etc/redis-test').only_with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-test',
        'mode'    => '0755',
        'owner'   => 'test',
        'group'   => 'test',
        'notify'  => 'Service[redis-test]',
      })
    end
  end


  context 'with default parameters on testos operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
      } 
    }
    it do
      should contain_file('tp_dir_/etc/redis-testos').only_with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-testos',
        'mode'    => '0755',
        'owner'   => 'test',
        'group'   => 'test',
        'notify'  => 'Service[redis-testos]',
      })
    end
  end


  context 'with default parameters on testos 0.0.1 operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1',
      } 
    }
    it do
      should contain_file('tp_dir_/etc/redis-testos001').with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-testos001',
        'mode'    => '0755',
        'owner'   => 'test',
        'group'   => 'test',
        'notify'  => 'Service[redis-testos001]',
      })
    end
  end


  context 'with custom parameters' do
    let(:params) {
      {
        'source' => 'puppet:///modules/site/redis/redis.conf',
        'path'   => '/opt/etc/redis',
        'mode'   => '0777',
        'owner'  => 'mytest',
        'group'  => 'mytest',
      }
    }
    it do
      should contain_file('tp_dir_/opt/etc/redis').with({
        'ensure'  => 'directory',
        'path'    => '/opt/etc/redis',             
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
        'notify'  => 'Service[redis]',                    
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
        'source' => 'puppet:///modules/site/redis/redis.conf',
        'mode'   => '0777',
        'owner'  => 'mytest',
        'group'  => 'mytest',
      }
    }
    it do
      should contain_file('tp_dir_/etc/redis-testos001').with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-testos001',
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
        'notify'  => 'Service[redis-testos001]',
      })
    end
  end


  context 'with dir purging' do
    let(:params) {
      {
        'purge'        => true,
        'force'        => true,
        'recurse'      => true,
        'source'       => 'puppet:///modules/site/redis/redis.conf',
      }
    }
    it do 
      should contain_file('tp_dir_/etc/redis').with({
        'ensure'  => 'directory',                           
        'path'    => '/etc/redis',             
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'purge'   => true,
        'force'   => true,
        'recurse' => true,
      })                                                  
    end                                                   
  end 


  context 'with vcsrepo' do
    let(:params) {
      {
        'vcsrepo' => 'git',
        'source'  => 'https://github.com/example42/puppet-tp.git',
        'owner'   => 'mytest',
      }
    }
    it do 
      should contain_vcsrepo('/etc/redis').with({
        'ensure'   => 'present',                           
        'provider' => 'git',             
        'source'   => 'https://github.com/example42/puppet-tp.git',
        'owner'    => 'mytest',
        'group'    => 'root',
      })
    end
  end
end
