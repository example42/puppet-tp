require 'spec_helper'

describe 'tp::service' do
  let(:title) { 'my_app' }
  let(:pre_condition) { "include tp" }
  let(:params) do
    {
      ensure: 'present',
      settings: {
        'description' => 'My App Service',
        'website' => 'https://myapp.example.com',
        'process_user' => 'my_app_user',
        'process_group' => 'my_app_group',
        'init_file_path' => '/etc/default/my_app',
        'install' => {
          'systemd_symlink' => '/etc/systemd/system/multi-user.target.wants/my_app.service',
        },
        'systemd_settings' => {
          'Unit' => {
            'After' => 'network.target',
          },
          'Service' => {
            'ExecStart' => '/usr/local/bin/my_app',
            'TimeoutStartSec' => '90s',
          },
          'Install' => {
            'WantedBy' => 'default.target',
          },
        },
      },
      on_missing_data: 'notify',
      manage_service: true,
      command_path: '/usr/local/bin/my_app',
      data_module: 'tinydata',
      mode: 'normal',
    }
  end
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_service('my_app').with(ensure: 'running') }

      it do
        is_expected.to contain_file('/lib/systemd/system/my_app.service').with(
          ensure: 'present',
          path: '/lib/systemd/system/my_app.service',
          owner: 'root',
          group: 'root',
          mode: '0644',
          notify: 'Exec[tp systemctl daemon-reload]',
          before: 'Service[my_app]',
        )
      end

      it do
        is_expected.to contain_file('/etc/systemd/system/multi-user.target.wants/my_app.service').with(
          ensure: 'link',
          target: '/lib/systemd/system/my_app.service',
          notify: 'Exec[tp systemctl daemon-reload]',
        )
      end
    end
  end
end
