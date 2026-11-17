require 'rspec'
require 'serverspec'
require 'shellwords'

# Regression test for hostapd dropping same-SSID neighbors from beacon
# RNR (IE 201): stock hostapd_eid_nr_db() matches on short_ssid instead
# of own BSSID. The script is behavior-only (see the header of
# spec/files/hostapd_rnr_same_ssid_test.sh). Exit 0 = PASS, 1 = FAIL,
# 77 = SKIP (rnr off, no hostapd object, cannot capture, missing tools).
RSpec.shared_examples "openwrt hostapd rnr same ssid" do
  rnr_test = File.read(File.expand_path('../../files/hostapd_rnr_same_ssid_test.sh', __dir__))

  describe "beacon RNR (IE 201) same-SSID neighbors" do
    it "includes a same-SSID, different-BSSID neighbor in the AP's own beacon" do
      result = command("sh -c #{Shellwords.escape(rnr_test)}")
      puts "\n#{result.stdout}"
      skip("hostapd RNR same-SSID test skipped:\n#{result.stdout}") if result.exit_status == 77
      expect(result.exit_status).to eq(0), "hostapd RNR same-SSID test failed:\n#{result.stdout}#{result.stderr}"
    end
  end
end
