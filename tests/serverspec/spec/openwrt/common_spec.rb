require 'spec_helper'

DEFAULT_PKGS=["apinger", "bash", "logrotate",
              "python3", "rsyslogd", "zabbix_agentd"]

DEFAULT_SERVICES=["apinger", "crond", "rsyslogd", "zabbix"]

DEFAULT_PKGS.each do |pkg|
  describe command("which #{pkg} 2> /dev/null") do
    its(:exit_status) { should eq 0 }
  end
end

DEFAULT_SERVICES.each do |service|
  describe command("pgrep #{service}") do
    its(:exit_status) { should eq 0 }
  end
end

# Validate rsyslogd config
# TODO: After fixing issue #125
#describe command('rsyslogd -N1') do
#  its(:exit_status) { should eq 0 }
#end

describe file('/root/bin/wifi-details.sh') do
    it { should exist }
    it { should be_mode 750 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
end
