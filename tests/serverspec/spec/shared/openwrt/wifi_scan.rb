require 'rspec'
require 'serverspec'
require 'shellwords'

# Regression test for the `iwinfo <if> scan` hang seen on the APs at SCALE 23x (March 2026):
# ucode's nl80211.waitfor() busy-spins on a non-blocking event socket
# (fixed upstream in ucode 520d9f4c, overrun recovery in 0bfb7b97) and
# iwinfo.uc accepts the scan-done event of the other radio (fixed upstream
# in openwrt 62d9f2d4f22a). Also fails if the 5 GHz scan prints 2.4 GHz cells.
#
# The script runs on the AP over the normal ssh backend; it needs only
# busybox + ucode (no `timeout`, no `iw`) and kills everything it starts
# after DEADLINE seconds. Exit 0 = PASS, 1 = FAIL, 77 = SKIP (no 5 GHz AP
# interface, or the 5 GHz radio refuses to scan, e.g. DFS/CAC -> EBUSY).
# See the header of spec/files/wifi_scan_spin_test.sh for tunables.
RSpec.shared_examples "openwrt wifi scan" do
  spin_test = File.read(File.expand_path('../../files/wifi_scan_spin_test.sh', __dir__))

  describe "wifi scan with both radios scanning" do
    it "does not busy-spin or hang iwinfo (ucode nl80211 waitfor)" do
      result = command("sh -c #{Shellwords.escape(spin_test)}")
      puts "\n#{result.stdout}"
      skip("wifi scan spin test skipped:\n#{result.stdout}") if result.exit_status == 77
      expect(result.exit_status).to eq(0), "wifi scan spin test failed:\n#{result.stdout}#{result.stderr}"
    end
  end
end
