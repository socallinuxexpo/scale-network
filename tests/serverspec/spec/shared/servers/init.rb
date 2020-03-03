require 'rspec' # You could require a spec_helper here - you just need to RSpec functionality to defined shared examples
require 'serverspec' # If you want to use serverspec matchers, you will need this too

RSpec.shared_examples "servers" do

  DEFAULT_PKGS=["chrony","zabbix-agent"]

  DEFAULT_SERVICES=["chrony", "systemd-resolved", "zabbix-agent"]

  DEFAULT_PKGS.each do |bin|
    describe package(bin) do
      it { should be_installed }
    end
  end

  DEFAULT_SERVICES.each do |service|
    describe service(service) do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe package("apparmor") do
    it { should_not be_installed }
  end

end
