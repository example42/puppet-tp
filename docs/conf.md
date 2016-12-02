



To configure nginx.conf with a custom template you can write:

    tp::conf { 'nginx':
      template => 'site/nginx/nginx.conf.erb',
    }

Given the above example, we can edit the referenced file with:

    [root@centos7-p4 ~]# mkdir -p /vagrant/modules_local/site/templates/nginx
    [root@centos7-p4 ~]# vi /vagrant/modules_local/site/templates/nginx/nginx.conf.erb


You can pass an hash of custom key/values using the ```options_hash``` parameter:

    $nginx_options = {
      'worker_processes'   => '12',
      'worker_connections' => '512',
    }
    tp::conf { 'nginx':
      template     => 'site/nginx/nginx.conf.erb',
      options_hash => $nginx_options,
    }

An then, in your ```$modulepath/site/templates/ningx/nginx.conf.erb``` have something like:

    # File managed by Puppet
    user              <%= @settings['process_user'] %> <%= @settings['process_group'] %>;
    worker_processes  <%= @options['worker_processes'] %>;
    pid               /var/run/nginx.pid;

    events {
      use epoll;
      worker_connections <%= @options['worker_connections'] %>;
      multi_accept on;
    }

Some explanations are needed here. Your ```options_hash``` parameter is accessed, in the erb file, via the ```@options``` variable (You can use also ```@options_hash```) because in ```tp::conf``` we plan to merge the values from @options_hash to a set of default options (compliant with the underlying OS).
You have at disposal also the ```@settings``` hash which contains OS specific data for the managed application. To have an idea of what kind of data we provide for each supported application check in [```data/nginx/default.yaml```](https://github.com/example42/puppet-tp/blob/master/data/nginx/default.yaml).


There are many options in ```tp::conf``` that let you manage every aspect of your configurations, for example we can manage its permissions, how to populate its content (with static source, epp or erb templates, plain content...), if to trigger a service restart when the files changes (by default the relevant service, if present, is restarted) and so on.
The ```tp::conf``` define works perfectly when used with ```tp::install``` but can cope well with packages installed via other modules.
