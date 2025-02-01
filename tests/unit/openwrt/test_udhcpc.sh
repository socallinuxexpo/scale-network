#!/bin/bash
#
# Tests some scenarios of the udhcpc.user script. There is room for improvement
# here to mock out uci to return radio status as part of the test. There is
# also room to cover more of the udhcpcp.user script like setting the hostname
# and chaning the config version.
#
TOPDIR=$(git rev-parse --show-toplevel)
export PATH="$TOPDIR/tests/unit/openwrt:$PATH"

test_dhcp(){
	testname=$1
	echo "Running $testname"
	export UCILOG="$testname"_uci.log
	export opt224=$2 	# radio0 channel | off
	export opt225=$3 	# radio1 channel | off

	echo "" > $UCILOG
	bash $TOPDIR/openwrt/files/etc/udhcpc.user renew

	if ! diff "$testname"_uci.log "$testname"_expected.log; then
		echo "FAILED: $testname"
		exit 1
	fi
}


cat > both_off_expected.log << EOF

show wireless.radio0.channel
show wireless.radio1.channel
set wireless.radio0.disabled=1
set wireless.radio1.disabled=1
commit
EOF
test_dhcp "both_off" off OFF

cat > enable_0_expected.log << EOF

show wireless.radio0.channel
show wireless.radio1.channel
set wireless.radio0.channel=3
set wireless.radio0.disabled=0
set wireless.radio1.disabled=1
commit
EOF
test_dhcp "enable_0" 3 OFF

cat > enable_1_expected.log << EOF

show wireless.radio0.channel
show wireless.radio1.channel
set wireless.radio0.channel=3
set wireless.radio0.disabled=0
set wireless.radio1.channel=4
set wireless.radio1.disabled=0
commit
EOF
test_dhcp "enable_1" 3 4

echo "PASS"
