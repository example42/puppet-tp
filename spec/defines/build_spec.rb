# frozen_string_literal: true

require 'spec_helper'

describe 'tp::build' do
  let(:title) { 'namevar' }


  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'build_dir' => '/tmp/build',
        }
      end
      it { is_expected.to compile }
    end
  end
end
