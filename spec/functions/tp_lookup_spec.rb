#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe "the tp_lookup function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:facts) { { :osfamily => 'test', } }

  it "should exist" do
    expect(Puppet::Parser::Functions.function("tp_lookup")).to eq("function_tp_lookup")
  end

  it "should raise a ParseError if there is less than 3 arguments" do
    expect { scope.function_tp_lookup(["1","2"]) }.to( raise_error(Puppet::ParseError))
  end

  context "with test params" do
    skip "should return a settings hash given test params" do
      result = scope.function_tp_lookup(["test","settings","tp","merge"])
      expect(result).to eq( {
        "init_file_path"     => "/etc/sysconfig/test",
        "package_name"       => "test",
        "service_name"       => "test",
        "config_file_path"   => "/etc/test/test.conf",
        "config_dir_path"    => "/etc/test",
        "conf_dir_path"      => "/etc/test/conf.d",
        "pid_file_path"      => "/var/run/test.pid",
        "log_file_path"      => "/var/log/test/test.log",
        "log_dir_path"       => "/var/log/test",
        "process_name"       => "test",
        "process_user"       => "test",
        "process_group"      => "test",
        "tcp_port"           => "6379",
        "package_ensure"     => "present",
        "service_ensure"     => "running",
        "service_enable"     => true,
        "config_file_owner"  => "root",
        "config_file_group"  => "root",
        "config_file_mode"   => "0644",
        "config_dir_owner"   => "root",
        "config_dir_group"   => "root",
        "config_dir_mode"    => "0755",
        "config_dir_purge"   => false,
        "config_dir_recurse" => true
        } )
    end
  end
end
