#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'bool2ensure' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params(true).and_return("present") }
  it { is_expected.to run.with_params('true').and_return("present") }
  it { is_expected.to run.with_params('yes').and_return("present") }
  it { is_expected.to run.with_params('y').and_return("present") }
  it { is_expected.to run.with_params('1').and_return("present") }
  it { is_expected.to run.with_params('').and_return("present") }
  it { is_expected.to run.with_params(false).and_return("absent") }
  it { is_expected.to run.with_params('false').and_return("absent") }
  it { is_expected.to run.with_params('no').and_return("absent") }
  it { is_expected.to run.with_params('n').and_return("absent") }
  it { is_expected.to run.with_params('0').and_return("absent") }

end
