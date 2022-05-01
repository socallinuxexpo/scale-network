require 'spec_helper'

require_relative '../shared/openwrt/init.rb'

describe "shared" do
  include_examples "openwrt"
end

describe command("cat /etc/ssh/sshd_config | grep '^PasswordAuthentication' | cut -d' ' -f2") do
    its(:stdout) { should match no }
    its(:exit_status) { should eq 0 }
end
