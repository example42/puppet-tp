#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'tp_install' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params('app') }
  context 'with 1st arg = apache' do
    it do
      is_expected.to run.with_params('apache', {})
      expect(catalogue).to contain_tp__install('apache')
    end
  end
  context 'with 1st arg = apache and 2nd arg = { ensure => absent }' do
    it do
      is_expected.to run.with_params('apache', { 'ensure' => 'absent' })
      expect(catalogue).to contain_tp__install('apache').with_ensure('absent')
    end
  end
end
