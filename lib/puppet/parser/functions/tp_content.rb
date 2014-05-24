module Puppet::Parser::Functions
  Puppet::Parser::Functions.newfunction(:tp_content,
                                        :type => :rvalue,
                                        :doc => <<-'ENDOFDOC'
  Takes an optional content and an optional template name to calculate the actual
  contents of a file.

  This small function abbreviates the default initialisation boilerplate of
  stdmod modules.
  ENDOFDOC
  ) do |args|
    content = args[0]
    template_name = args[1]
    epp_name = args[2]

    Puppet::Parser::Functions.autoloader.loadall

    return content if content != ''
    return function_template([template_name]) if template_name != ''
    return function_epp([epp_name]) if epp_name != ''

    return :undef
  end
end
