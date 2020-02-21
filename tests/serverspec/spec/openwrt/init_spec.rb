require 'spec_helper'

require_relative '../shared/openwrt/init.rb'


KERNEL = command("uname -a").stdout.chomp
OPENWRT_REL = command("cat /etc/os-release | grep -E 'BUILD_ID|OPENWRT_ARCH|OPENWRT_BOARD'").stdout.chomp
SCALE_REL = command("cat /etc/scale-release").stdout.chomp

puts "\nImage info:\n#{KERNEL}\n#{SCALE_REL}\n#{OPENWRT_REL}"

describe "shared" do
  include_examples "openwrt"
end
