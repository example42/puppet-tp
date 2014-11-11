# Install'em all

tp::install { 'apache': }
tp::install { 'autofs': }
tp::install { 'clvm': }
tp::install { 'fail2ban': }
tp::install { 'freeradius': }
tp::install { 'heartbeat': }
tp::install { 'libvirt': }
# tp::install { 'lighttpd': }
tp::install { 'mailx': }
# tp::install { 'msmtp': }
# tp::install { 'openntpd': }
tp::install { 'openssh': }
tp::install { 'redis': }
tp::install { 'samba': }
# tp::install { 'sysklogd': }
# tp::install { 'tftpd': }
tp::install { 'xinetd': }


# Tests
/*
tp::install { 'apache':
  files  => {
    '/tmp/apache.conf' => { content => 'test' } ,
  },
}

tp::conf { 'apache::test':
  content => test,
}
tp::conf { 'openssh::test':
  content => test,
}
tp::conf { 'redis::test':
  content => test,
}
*/
