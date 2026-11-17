require 'rspec'
require 'serverspec'
require 'shellwords'

# Regression test for prometheus-node-exporter-lua still exporting
# wifi_network_quality / wifi_network_signal_dbm (libiwinfo averages
# and clamps station signal, so the values are meaningless). The script
# is behavior-only (see the header of spec/files/wifi_lua_metrics_test.sh).
# Exit 0 = PASS, 1 = FAIL, 77 = SKIP (exporter not running).
RSpec.shared_examples "openwrt wifi lua metrics" do
  metrics_test = File.read(File.expand_path('../../files/wifi_lua_metrics_test.sh', __dir__))

  describe "prometheus-node-exporter-lua wifi collector metrics" do
    it "exports bitrate or noise and does not export quality or signal_dbm" do
      result = command("sh -c #{Shellwords.escape(metrics_test)}")
      puts "\n#{result.stdout}"
      skip("wifi lua metrics test skipped:\n#{result.stdout}") if result.exit_status == 77
      expect(result.exit_status).to eq(0), "wifi lua metrics test failed:\n#{result.stdout}#{result.stderr}"
    end
  end
end
