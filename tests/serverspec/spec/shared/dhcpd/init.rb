require 'rspec' # You could require a spec_helper here - you just need to RSpec functionality to defined shared examples
require 'serverspec' # If you want to use serverspec matchers, you will need this too

RSpec.shared_examples "dhcpd" do

  DEFAULT_PKGS=['isc-dhcp-server']
  DEFAULT_BINS=[]
  REMOVED_BINS=[]

  DEFAULT_SERVICES=["isc-dhcp-server", "isc-dhcp-server6"]

  DEFAULT_BINS.each do |bin|
    describe command("which #{bin} 2> /dev/null") do
      its(:exit_status) { should eq 0 }
    end
  end

  DEFAULT_PKGS.each do |bin|
    describe package(bin) do
      it { should be_installed }
    end
  end

  REMOVED_BINS.each do |bin|
    describe command("which #{bin} 2> /dev/null") do
      its(:exit_status) { should eq 1 }
    end
  end

  DEFAULT_SERVICES.each do |service|
    describe service(service) do
      it { should be_enabled }
      it { should be_running }
    end
  end

  # Test dhcpd config
  describe command('dhcpd -t -cf /etc/dhcp/dhcpd.conf') do
    its(:exit_status) { should eq 0 }
  end

  # Test leases
  describe command('dhcpd -T') do
    its(:exit_status) { should eq 0 }
  end

  describe command('dhcpd -t -6 -cf /etc/dhcp/dhcpd6.conf') do
    its(:exit_status) { should eq 0 }
  end

  # TODO: Set pools via server config
  # ipv6 pools are not set
  #describe command('dhcpd -T -6') do
  #  its(:exit_status) { should eq 0 }
  #end

  describe command('rsyslogd -N1') do
    its(:exit_status) { should eq 0 }
  end
end
