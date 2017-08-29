#! /usr/bin/env ruby -S rspec
require 'spec_helper'
apps = ['rsyslog','openssh','elasticsearch','sysdig','puppet-agent']

describe 'tp_lookup' do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'centos-7-x86_64' || k == 'ubuntu-16.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context "the tp_lookup function" do
        let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
        
        it "should exist" do
          expect(Puppet::Parser::Functions.function("tp_lookup")).to eq("function_tp_lookup")
        end
      
        it "should raise a ParseError if there are less than 3 arguments" do
          expect { scope.function_tp_lookup(["1"]) }.to( raise_error(Puppet::Error))
          expect { scope.function_tp_lookup(["1","2"]) }.to( raise_error(Puppet::Error))
        end
      end
      apps.each do | app |
        appdata=YAML.safe_load(File.read(File.join(File.dirname(__FILE__), "../tpdata/#{os}/#{app}")))
        describe "with app #{app}" do
          it { is_expected.to run.with_params(app,'settings','tinydata','merge').and_return(appdata) }
        end
      end
    end
  end
end
