type Tp::Settings = Struct[{

  Optional[package_name] => Variant[String,Array],
  Optional[package_ensure] => String,

  Optional[service_name] => Variant[String,Array],
  Optional[service_enable] => Boolean,
  Optional[service_ensure] => Enum["running", "stopped"],

  Optional[process_name] => String,
  Optional[process_extra_name] => String,
  Optional[process_user] => String,
  Optional[process_group] => String,

  Optional[config_file_path] => Stdlib::Absolutepath,
  Optional[config_file_owner] => String,
  Optional[config_file_group] => String,
  Optional[config_file_mode] => String,

  Optional[config_dir_path] => Stdlib::Absolutepath,
  Optional[config_dir_owner] => String,
  Optional[config_dir_group] => String,
  Optional[config_dir_mode] => String,
  Optional[config_dir_recurse] => Boolean,

  Optional[log_file_path] => Stdlib::Absolutepath,
  Optional[pid_file_path] => Stdlib::Absolutepath,
  Optional[init_file_path] => Stdlib::Absolutepath,
  Optional[log_file_path] => Stdlib::Absolutepath,

  Optional[conf_dir_path] => Stdlib::Absolutepath,
  Optional[data_dir_path] => Stdlib::Absolutepath,
  Optional[plugins_dir_path] => Stdlib::Absolutepath,
  Optional[modules_dir_path] => Stdlib::Absolutepath,

  Optional[tcp_port] => Variant[String,Integer],
  Optional[udp_port] => Variant[String,Integer],

  Optional[nodaemon_args] => String,
}]
