require 'puppet/face'

Puppet::Face.define(:tp, '0.0.1') do
  copyright "Example 42", 2014
  license   "Apache 2 license; see COPYING"

  summary "Tiny Puppet commands."

  description <<-TEXT
    Run tp commands to interact with tp managed applications

    setup - Install tp cli command
    install - Install any application with tp (relevant tinydata must exist)
    test - Check the status of the managed resources
    log - Tail logs related to the application
  TEXT

  action :test do
    summary "Check the status of tp managed resources."
    description <<-TEXT
      Run tests
    TEXT
    when_invoked do |app='', options|
      exec ( "tp test " + app )
    end
  end

  action :info do
    summary "Show information about tp managed applications."
    option("--[no-]verbose") do
      summary "Whether or not print more verbose output"
    end
    when_invoked do |app, options|
      exec ( "tp info " + app )
    end
  end

  action :log do
    summary "Tail all the logs relevant to an application."
    when_invoked do |app, options|
      exec ( "tp log " + app )
    end
  end

  action :install do
    summary "Install any application on any OS (if tinydata available)."
    when_invoked do |app, options|
      exec ( "puppet apply -t -e 'tp::install { " + app + ": auto_prerequisites => true }'")
    end
  end

  action :setup do
    summary "Setup TinyPuppet for cli usage."
    when_invoked do |options|
      exec ( "puppet apply -t -e 'include tp'")
    end
  end


end
