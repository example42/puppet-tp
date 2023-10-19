#! /usr/bin/env ruby -S rspec
require 'spec_helper'
apps = ['rsyslog','openssh','elasticsearch','sysdig','icinga2']

describe 'tp_lookup' do
  on_supported_os(facterversion: '2.4').select { |k, _v| k == 'redhat-8-x86_64' || k == 'ubuntu-22.04-x86_64' }.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context "the tp_lookup function" do
        let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
        
        it "should exist" do
          expect(Puppet::Parser::Functions.function("tp_lookup")).to eq("function_tp_lookup")
        end
      
        it { is_expected.to run.with_params.and_raise_error(Puppet::ParseError, %r{wrong number of arguments}i) }
        it { is_expected.to run.with_params(["1"]).and_raise_error(Puppet::ParseError, %r{wrong number of arguments}i) }
        it { is_expected.to run.with_params(["1","2"]).and_raise_error(Puppet::ParseError, %r{wrong number of arguments}i) }

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
