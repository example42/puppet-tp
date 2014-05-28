
require 'puppet'

class Cache
  def initialize
    @cache = {}
  end

  @@instance = Cache.new

  def self.instance
    return @@instance;
  end

  def conf(app)
    puts Puppet::Module.find("tp", compiler.environment.to_s)
  end
end