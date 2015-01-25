require 'spec_helper'

describe 'tp::dir', :type => :define do

  let (:title) { 'redis' }

  context 'with title redis' do
    it do
      should contain_file('/etc/redis').only_with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis',
        'mode'    => '0755',
        'owner'   => 'root',
        'group'   => 'root',
        'require' => 'Package[redis]',
        'notify'  => 'Service[redis]',
      })
    end
  end


  context 'with title redis on test osfamily' do
    let(:facts) {
      {
        :osfamily => 'test',
      } 
    }
    it do
      should contain_file('/etc/redis-test').only_with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-test',
        'mode'    => '0755',
        'owner'   => 'test',
        'group'   => 'test',
        'require' => 'Package[redis-test]',
        'notify'  => 'Service[redis-test]',
      })
    end
  end


  context 'with title redis on testos operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
      } 
    }
    it do
      should contain_file('/etc/redis-testos').only_with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-testos',
        'mode'    => '0755',
        'owner'   => 'test',
        'group'   => 'test',
        'require' => 'Package[redis-testos]',
        'notify'  => 'Service[redis-testos]',
      })
    end
  end


  context 'with title redis on testos 0.0.1 operatingsystem' do
    let(:facts) {
      {
        :osfamily => 'test',
        :operatingsystem => 'testos',
        :operatingsystemrelease => '0.0.1',
      } 
    }
    it do
      should contain_file('/etc/redis-testos001').with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-testos001',
        'mode'    => '0755',
        'owner'   => 'test',
        'group'   => 'test',
        'require' => 'Package[redis-testos001]',
        'notify'  => 'Service[redis-testos001]',
      })
    end
  end

  context 'with custom source, path and vcsrepo' do
    let(:params) {
      {
        'source'  => 'https:///github.com/example42/puppet-tp',
        'path'    => '/opt/tp',
        'vcsrepo' => 'git',
      }
    }
    it do
      should contain_vcsrepo('/opt/tp').only_with({
        'ensure'   => 'present',
        'path'     => '/opt/tp',             
        'source'   => 'https:///github.com/example42/puppet-tp',
        'owner'    => 'root',
        'group'    => 'root',
        'provider' => 'git',
      })
    end
    it { should have_file_resource_count(0) }
  end 

  context 'with custom source, path and permissions' do
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
      should contain_file('/opt/etc/redis').only_with({
        'ensure'  => 'directory',
        'path'    => '/opt/etc/redis',             
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
        'require' => 'Package[redis]',                    
        'notify'  => 'Service[redis]',                    
      })                                                  
    end                                                   
  end 


  context 'with title redis and custom parameters on testos 0.0.1 operatingsystem' do
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
      should contain_file('/etc/redis-testos001').with({
        'ensure'  => 'directory',
        'path'    => '/etc/redis-testos001',
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'mode'    => '0777',                              
        'owner'   => 'mytest',
        'group'   => 'mytest',                              
        'require' => 'Package[redis-testos001]',
        'notify'  => 'Service[redis-testos001]',
      })
    end
  end


  context 'with title redis and recursive dir purging' do
    let(:params) {
      {
        'purge'        => true,
        'force'        => true,
        'recurse'      => true,
        'source'       => 'puppet:///modules/site/redis/redis.conf',
      }
    }
    it do 
      should contain_file('/etc/redis').with({
        'ensure'  => 'directory',                           
        'path'    => '/etc/redis',             
        'source'  => 'puppet:///modules/site/redis/redis.conf',
        'purge'   => true,
        'force'   => true,
        'recurse' => true,
      })                                                  
    end                                                   
  end 


  context 'with title apache on RedHat with dir_type = data' do
    let(:title) { 'apache' }
    let(:params) { {
        'dir_type'  => 'data',
        'source'    => 'puppet:///modules/site/apache/default_site',
    } }
    let(:facts) { {
        'osfamily'     => 'RedHat',
    } }

    it do 
      should contain_file('/var/www/html').with({
        'ensure'  => 'directory',                           
        'path'    => '/var/www/html',             
        'source'  => 'puppet:///modules/site/apache/default_site',
      })                                                  
      end
  end 


  context 'with an absolute path as title and vcsrepo' do
    let (:title) { '/opt/tp' }
    let(:params) {
      {
        'vcsrepo' => 'git',
        'source'  => 'https://github.com/example42/puppet-tp.git',
        'owner'   => 'mytest',
      }
    }
    it do 
      should contain_vcsrepo('/opt/tp').with({
        'ensure'   => 'present',                           
        'provider' => 'git',             
        'source'   => 'https://github.com/example42/puppet-tp.git',
        'owner'    => 'mytest',
        'group'    => 'root',
      })
    end
  end

  context 'with an absolute path as title and source' do
    let (:title) { '/opt/tools' }
    let(:params) { {
        'source'  => 'puppet:///modules/site/tools',
    } }
    it do 
      should contain_file('/opt/tools').with({
        'ensure'  => 'directory',                          
        'path'    => '/opt/tools',             
        'source'  => 'puppet:///modules/site/tools',
      })                                                  
    end                                                   
  end 

end
