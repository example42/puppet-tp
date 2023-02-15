type Tp::Settings = Struct[{

    # v3
    Optional[upstream_repo] => Boolean,

    Optional[package_name] => Variant[String,Array],
    Optional[package_ensure] => String,
    Optional[package_params] => Hash,

    Optional[service_name] => Variant[String,Array],
    Optional[service_enable] => Boolean,
    Optional[service_ensure] => Enum['running', 'stopped'],
    Optional[service_params] => Hash,

    Optional[process_name] => String,
    Optional[process_extra_name] => String,
    Optional[process_user] => String,
    Optional[process_group] => String,

    Optional[config_file_path] => Stdlib::Absolutepath,
    Optional[config_file_owner] => String,
    Optional[config_file_group] => String,
    Optional[config_file_mode] => String,
    Optional[config_file_params] => Hash,
    Optional[config_file_format] => String,
    Optional[config_file_template] => String,
    Optional[validate_cmd] => String,

    Optional[config_dir_path] => Stdlib::Absolutepath,
    Optional[config_dir_owner] => String,
    Optional[config_dir_group] => String,
    Optional[config_dir_mode] => String,
    Optional[config_dir_recurse] => Boolean,
    Optional[config_dir_params] => Hash,

    Optional[log_file_path] => Variant[Stdlib::Absolutepath,Array[Stdlib::Absolutepath]],
    Optional[pid_file_path] => Stdlib::Absolutepath,
    Optional[init_file_path] => Stdlib::Absolutepath,
    Optional[init_file_template] => String,

    Optional[conf_dir_path] => Stdlib::Absolutepath,
    Optional[data_dir_path] => Stdlib::Absolutepath,
    Optional[plugins_dir_path] => Stdlib::Absolutepath,
    Optional[modules_dir_path] => Stdlib::Absolutepath,
    Optional[home_dir_path] => Stdlib::Absolutepath,

    Optional[tcp_port] => Variant[String,Integer],
    Optional[udp_port] => Variant[String,Integer],

    Optional[nodaemon_args] => String,
    Optional[dockerfile_prerequisites] => String,
    Optional[docker_image] => String,

    Optional[package_prerequisites] => Array,
    Optional[tp_prerequisites] => Array,
    Optional[exec_prerequisites] => Hash,
    Optional[exec_postinstall] => Hash,

    Optional[extra_prerequisites] => Hash,
    Optional[extra_postinstall] => Hash,

    Optional[repo_package_name] => String,
    Optional[repo_package_url] => String,
    Optional[repo_package_provider] => String,
    Optional[repo_package_params] => Hash,
    Optional[repo_file_url] => String,
    Optional[repo_url] => String,
    Optional[repo_name] => String,
    Optional[repo_description] => String,
    Optional[repo_filename] => String,
    Optional[key] => String,
    Optional[key_url] => String,
    Optional[include_src] => String,
    Optional[yumrepo_params] => Hash,

    Optional[apt_repos] => String,
    Optional[apt_key_server] => String,
    Optional[apt_key_fingerprint] => String,
    Optional[apt_release] => String,
    Optional[apt_pin] => String,
    Optional[yum_priority] => String,
    Optional[yum_mirrorlist] => String,
    Optional[zypper_repofile_url] => String,
    Optional[brew_tap] => String,

    Optional[git_use] => Boolean,
    Optional[git_source] => String,
    Optional[git_destination] => String,

    # v3 and v4
    Optional[info_commands]    => Hash[String,Variant[String,Tp::Settings::Command]],
    Optional[run_commands]     => Hash[String,Variant[String,Tp::Settings::Command]],
    Optional[debug_commands]   => Hash[String,Variant[String,Tp::Settings::Command]],
    Optional[version_command]  => String,
    Optional[help_command]     => String,
    Optional[package_provider] => String,

    # v4
    Optional[preinstall]     => Hash[String,Variant[String,Array,Hash]],
    Optional[postinstall]    => Hash[String,Variant[String,Array,Hash]],

    Optional[init_system]    => String,

    Optional[configs]        => Hash[String,Tp::Settings::Config],
    Optional[user_configs]   => Hash[String,Tp::Settings::Config],
    Optional[dirs]           => Hash[String,Tp::Settings::Dir],
    Optional[user_dirs]      => Hash[String,Tp::Settings::Dir],
    Optional[ports]          => Hash[String,Tp::Settings::Port],
    Optional[release]        => Tp::Settings::Release,
    Optional[setup]          => Tp::Settings::Setup,
    Optional[build]          => Tp::Settings::Build,
    Optional[install_method] => Enum['package', 'source', 'file', 'image'],
    Optional[docker_args]    => String,
    Optional[description]    => String,
    Optional[urls]           => Hash[String,Stdlib::HTTPUrl],
    Optional[packages]       => Hash[String,Tp::Settings::Package],
    Optional[services]       => Hash[String,Tp::Settings::Service],
    Optional[repos]          => Hash[String,Tp::Settings::Repo],

}]
