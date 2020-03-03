require 'rspec' # You could require a spec_helper here - you just need to RSpec functionality to defined shared examples
require 'serverspec' # If you want to use serverspec matchers, you will need this too

RSpec.shared_examples "resolvable" do

  RESOLVABLE=[
    "ntp.scale.lan",
    "loghost.scale.lan",
    "zabbix.scale.lan",
    "google.com"
  ]


  RESOLVABLE.each do |host|
    describe command("dig +short #{host} | grep -v -e '^$'") do
      its(:exit_status) { should eq 0 }
    end
  end
end
