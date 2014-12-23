require 'spec_helper'

describe 'tp::concat', :type => :define do

  context 'with redis defaults' do
    let(:title) { 'redis' }
    it { should compile.with_all_deps }
    it { should have_concat_resource_count(1) }
    it { should have_concat_fragment_resource_count(1) }
    it { should contain_concat("/etc/redis/redis.conf") } 
    it do
      should contain_concat('/etc/redis/redis.conf').with({
        'ensure'  => 'present',
        'path'    => '/etc/redis/redis.conf',
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
      should contain_concat('/etc/redis/redis.conf').with({
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
      should contain_concat('/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/etc/redis/redis.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
    it do 
      should contain_concat_fragment('/etc/redis/redis.conf_').with({
        'ensure'  => 'present',                           
        'target'  => '/etc/redis/redis.conf',             
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end                                                   
  end

  context 'with title heartbeat::head' do
    let(:title) { 'heartbeat::head' }
    let(:params) { {
        'template'     => 'tp/spec/spec.erb',
        'options_hash' => { 
          'key_a'  => 'value_a',
          'key_b'  => 'value_b',
        },
    } }
    it do
      should contain_concat('/etc/ha.d/ha.cf').with({
        'ensure'  => 'present',
        'path'    => '/etc/ha.d/ha.cf',
      })
    end
    it do 
      should contain_concat_fragment('/etc/ha.d/ha.cf_').with({
        'ensure'  => 'present',                           
        'target'  => '/etc/ha.d/ha.cf',     
        'content' => "key_a = value_a ; key_b = value_b\n",
      })                                                  
    end
  end


  context 'with title redis::head and content and path explicitly set' do
    let(:title) { 'redis::head' }
    let(:params) { {
        'content' => 'test',
        'path'    => '/opt/etc/redis/redis.conf',
      }
    }
    it do
      should contain_concat('/opt/etc/redis/redis.conf').with({
        'ensure'  => 'present',                           
        'path'    => '/opt/etc/redis/redis.conf',             
      })                                                  
    end                                                   
    it do 
      should contain_concat_fragment('/opt/etc/redis/redis.conf_head').with({
        'ensure'  => 'present',                           
        'target'  => '/etc/ha.d/ha.cf',     
        'content' => 'test',
      })                                                  
    end                                                   
  end 

end
