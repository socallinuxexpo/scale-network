require 'rspec' # You could require a spec_helper here - you just need to RSpec functionality to defined shared examples
require 'serverspec' # If you want to use serverspec matchers, you will need this too

RSpec.shared_examples "openwrt" do

  DEFAULT_BINS=["apinger", "bash", "logrotate",
                "python3", "rsyslogd", "zabbix_agentd",
                "tcpdump"]

  REMOVED_BINS=["snmpd", "dropbear"]

  DEFAULT_SERVICES=["apinger", "crond", "rsyslogd", "zabbix"]

  DEFAULT_BINS.each do |bin|
    describe command("which #{bin} 2> /dev/null") do
      its(:exit_status) { should eq 0 }
    end
  end

  REMOVED_BINS.each do |bin|
    describe command("which #{bin} 2> /dev/null") do
      its(:exit_status) { should eq 1 }
    end
  end

  DEFAULT_SERVICES.each do |service|
    describe command("pgrep #{service}") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe command('rsyslogd -N1') do
    its(:exit_status) { should eq 0 }
  end

  describe file('/root/bin/wifi-details.sh') do
      it { should exist }
      it { should be_mode 750 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
  end

  describe file('/root/bin/config-version.sh') do
      it { should exist }
      it { should be_mode 750 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
  end

  describe command('/root/bin/config-version.sh') do
    its(:exit_status) { should eq 0 }
  end

  # Look for config that doesnt exist
  describe command('/root/bin/config-version.sh -c 9999') do
    its(:exit_status) { should eq 1 }
  end

  describe file('/etc/scale-release') do
      it { should exist }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
  end

  # Make sure vars is not unset or empty
  # :pre_command doesnt work here since mutliple shell instances cant be used
  describe command("source /etc/scale-release && test -z $SCALE_VER") do
    its(:exit_status) { should eq 1 }
  end

  # Make sure var is not unset or empty
  describe command("source /etc/scale-release && test -z $OPENWRT_VER") do
    its(:exit_status) { should eq 1 }
  end

  describe file('/etc/resolv.conf') do
      it { should be_symlink }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
  end

  describe file('/etc/config/network') do
      it { should be_symlink }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
  end

  describe file('/etc/config/wireless') do
      it { should be_symlink }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
  end
end
