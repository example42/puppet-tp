module Puppet::Parser::Functions
  Puppet::Parser::Functions.newfunction(:tp_pick,
                                        :type => :rvalue,
                                        :doc => <<-EOS

  This function is similar to a coalesce function in SQL in that it will return
  the first value in a list of values that is not undefined or an empty string
  (two things in Puppet that will return a boolean false value). Typically,
  this function is used to check for a value in the Puppet Dashboard/Enterprise
  Console, and failover to a default value like the following:

    $real_jenkins_version = tp_pick($::jenkins_version, '1.449')

  The value of $real_jenkins_version will first look for a top-scope variable
  called 'jenkins_version' (note that parameters set in the Puppet Dashboard/
  Enterprise Console are brought into Puppet as top-scope variables), and,
  failing that, will use a default value of 1.449.

  Contrary to the tp_pick() function from stdlib, this one won't die if all values
  are empty.

  EOS
  ) do |args|
    args = args.compact
    args.delete(:undef)
    args.delete(:undefined)
    args.delete("")
    args << :undef
    return args[0]
  end
end

