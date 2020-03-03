require 'serverspec'
require 'net/ssh'

set :backend, :ssh

if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

host = ENV['TARGET_HOST']

options = Net::SSH::Config.for(host)

set :host,        options[:host_name] || host
set :ssh_options, options

# Setup some special options for openwrt tests
if ENV['TEST_TYPE'].start_with?('openwrt')
  options[:user] = 'root'
  # Disable sudo
  set :disable_sudo, true

  # Force os detection due to errors on openwrt
  set :os, :family => 'linux'
else
  #options[:user] ||= Etc.getlogin
  # TODO: Need to not hard code this
  # But ok to assume this user for now
  options[:user] = 'ubuntu'
end
# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C'

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'
