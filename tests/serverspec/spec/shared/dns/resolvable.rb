require 'rspec' # You could require a spec_helper here - you just need to RSpec functionality to defined shared examples
require 'serverspec' # If you want to use serverspec matchers, you will need this too

RSpec.shared_examples "resolvable" do

  DNSSERVERS = [
    "10.0.3.5",
    "10.128.3.5",
    "2001:470:f026:103::5",
    "2001:470:f026:503::5"
  ]

  RESOLVABLE=[
    "ntp.scale.lan",
    "loghost.scale.lan",
    "lobste.rs",
    "google.com"
  ]


  RESOLVABLE.each do |host|
    DNSSERVERS.each do |dnsserver|
      describe command("dig @#{dnsserver} +short #{host} A | grep -v -e '^$'") do
        its(:exit_status) { should eq 0 }
      end
      describe command("dig @#{dnsserver} +short #{host} AAAA | grep -v -e '^$'") do
        its(:exit_status) { should eq 0 }
      end
    end
  end
end
