require 'spec_helper'

require_relative '../shared/dhcpd/init.rb'
require_relative '../shared/dns/resolvable.rb'
require_relative '../shared/servers/init.rb'


describe "shared" do
  include_examples "servers"
  include_examples "dhcpd"
  include_examples "resolvable"
end
