#! /usr/bin/env ruby -S rspec
require 'spec_helper'
describe 'tp_content' do

  context 'Given different combinations of params' do
    let(:facts) {
      {
        :osfamily => 'RedHat',
      }
    }
  
    it { is_expected.not_to eq(nil) }
  
    it { is_expected.to run.with_params('test','tp/spec/osfamily.erb','tp/spec/osfamily.epp').and_return("test") }
    it { is_expected.to run.with_params('test','','').and_return("test") }
    it { is_expected.to run.with_params('test','','tp/spec/osfamily.epp').and_return("test") }
    it { is_expected.to run.with_params('test','tp/spec/osfamily.erb','').and_return("test") }
  
    it { is_expected.to run.with_params('','tp/spec/osfamily.erb','tp/spec/osfamily.epp').and_return("ERB: RedHat\n") }
    it { is_expected.to run.with_params('','tp/spec/osfamily.erb','').and_return("ERB: RedHat\n") }
  end

  if ENV['PARSER'] == 'future'
    skip 'When epp template is expected' do
      let(:facts) {
        {
          :osfamily => 'RedHat',
        }
      }
  
      it { is_expected.to run.with_params('','','tp/spec/osfamily.epp').and_return("EPP: RedHat\n") }
  
    end
  end
end
