require 'spec_helper'

#require_relative '../shared/openwrt/init.rb'
require_relative '../shared/openwrt/init.rb'

RESOLVABLE=["loghost.scale.lan", "zabbix.scale.lan", "google.com"]

describe "shared" do
  include_examples "openwrt"
end

RESOLVABLE.each do |host|
  describe command("nslookup #{host} 2> /dev/null") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match /server can\'t/ }
  end
end
