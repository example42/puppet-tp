class site {

  tp::conf { 'redis::red.conf':
      content => 'test',
  }

  tp::dir { 'redis':
      source => 'puppet:///modules/site/redis/test',
  }


}
