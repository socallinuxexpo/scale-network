#!/bin/sh

while true
do
  # Example of output
  # phy0-ap0/stations:,c4:13:29:8e:55,7a:68:c6:01:30,,phy1-ap0/stations:,96:0e:88:1b:67,ef:c4:1b:af:63,96:93:21:28:4e,b3:53:75:ba:9d,
  ls /sys/kernel/debug/ieee80211/phy*/net*/stations |cut -f 2- -d : | awk '{printf "%s,", $0} END{print ""}' |/usr/bin/logger -p local7.info -t "stats-wifi-stations"
  # da:16:9a:d7:e4:c6 RX: 154944 us TX: 181412 us Weight: 256 Deficit: VO: 12 us VI: 892 us BE: -461 us BK: 256 us
  #
  # da:16:9a:d7:e4:c6 EHT not supported HE not supported ht supported cap: 0x002d     RX LDPC         HT20    SM Power Save disabled  RX HT20 SGI     No RX STBC      Max AMSDU length: 3839 bytes    No DSSS/CCK HT40 ampdu factor/density: 3/6 MCS mask: ff ff 00 00 00 00 00 00 00 00 MCS tx params: 1 VHT not supported
  #
  # da:16:9a:d7:e4:c6 target 19999us interval 99999us ecn yes=tid ac backlog-bytes backlog-packets new-flows drops marks overlimit collisions tx-bytes tx-packets flags=0 2 0 0 3228 0 0 0 0 2034210 4612 0x2(RUN AMPDU)=1 3 0 0 0 0 0 0 0 0 0 0x0(RUN)=2 3 0 0 0 0 0 0 0 0 0 0x0(RUN)=3 2 0 0 0 0 0 0 0 0 0 0x0(RUN)=4 1 0 0 7 0 0 0 0 5091 11 0x2(RUN AMPDU)=5 1 0 0 0 0 0 0 0 0 0 0x0(RUN)=6 0 0 0 0 0 0 0 0 0 0 0x0(RUN)=7 0 0 0 63 0 0 0 0 5584 67 0x0(RUN)=8 2 0 0 0 0 0 0 0 0 0 0x0(RUN)=9 3 0 0 0 0 0 0 0 0 0 0x0(RUN)=10 3 0 0 0 0 0 0 0 0 0 0x0(RUN)=11 2 0 0 0 0 0 0 0 0 0 0x0(RUN)=12 1 0 0 0 0 0 0 0 0 0 0x0(RUN)=13 1 0 0 0 0 0 0 0 0 0 0x0(RUN)=14 0 0 0 0 0 0 0 0 0 0 0x0(RUN)=15 0 0 0 0 0 0 0 0 0 0 0x0(RUN)=
  find /sys/kernel/debug/ieee80211/phy0 -name airtime |cut -f 9 -d '/' |while read mac
  do
    syslogtag=`echo "$mac"|sed s/:/-/g`
    (echo -n "$mac "; cat /sys/kernel/debug/ieee80211/phy0/net*/stations/$mac/airtime| awk '{printf "%s ", $0} END{print ""}') |logger -p local7.info -t "stats-24-$syslogtag"
    (echo -n "$mac "; cat /sys/kernel/debug/ieee80211/phy0/net*/stations/$mac/*capa| awk '{printf "%s ", $0} END{print ""}') |logger -p local7.info -t "stats-24-$syslogtag-capa"
    (echo -n "$mac "; cat /sys/kernel/debug/ieee80211/phy0/net*/stations/$mac/aqm| awk '{printf "%s ", $0} END{print ""}') |logger -p local7.info -t "stats-24-$syslogtag-.capa"
  done
  find /sys/kernel/debug/ieee80211/phy1 -name airtime |cut -f 9 -d '/' |while read mac
  do
    syslogtag=`echo "$mac"|sed s/:/-/g`
    (echo -n "$mac "; cat /sys/kernel/debug/ieee80211/phy1/net*/stations/$mac/airtime| awk '{printf "%s ", $0} END{print ""}') |logger -p local7.info -t "stats-5-$syslogtag"
    (echo -n "$mac "; cat /sys/kernel/debug/ieee80211/phy1/net*/stations/$mac/*capa| awk '{printf "%s ", $0} END{print ""}') |logger -p local7.info -t "stats-5-$syslogtag-capa"
    (echo -n "$mac "; cat /sys/kernel/debug/ieee80211/phy1/net*/stations/$mac/aqm| awk '{printf "%s ", $0} END{print ""}') |logger -p local7.info -t "stats-5-$syslogtag-aqm"
  done
  # Phy 0, Phy band 0=Length:        1 |   2 - 10 |  11 - 19 |  20 - 28 |  29 - 37 |  38 - 46 |  47 - 55 |  56 - 79 |  80 -103 | 104 -127 | 128 -151 | 152 -175 | 176 -199 | 200 -223 | 224 -247 | =Count:     24463 |     9537 |     1285 |     1052 |      827 |      172 |        9 |        0 |        0 |        0 |        0 |        0 |        0 |        0 |        0 | =BA miss count: 21213==Tx Beamformer applied PPDU counts: iBF: 0, eBF: 0=Tx Beamformer Rx feedback statistics: All: 42, HE: 0, VHT: 42, HT: 0, BW20, NC: 105110, NR: 105110=Tx Beamformee successful feedback frames: 0=Tx Beamformee feedback triggered counts: 0=Tx multi-user Beamforming counts: 0=Tx multi-user MPDU counts: 0=Tx multi-user successful MPDU counts: 0=Tx single-user successful MPDU counts: 1160675==Tx MSDU statistics:=AMSDU pack count of 1 MSDU in TXD:   985195 ( 97%)=AMSDU pack count of 2 MSDU in TXD:    22203 (  2%)=AMSDU pack count of 3 MSDU in TXD:     4940 (  0%)=AMSDU pack count of 4 MSDU in TXD:     1550 (  0%)=AMSDU pack count of 5 MSDU in TXD:      562 (  0%)=AMSDU pack count of 6 MSDU in TXD:      302 (  0%)=AMSDU pack count of 7 MSDU in TXD:      163 (  0%)=AMSDU pack count of 8 MSDU in TXD:      573 (  0%)=

  # Phy 0, Phy band 0
  # Length:        1 |   2 - 10 |  11 - 19 |  20 - 28 |  29 - 37 |  38 - 46 |  47 - 55 |  56 - 79 |  80 -103 | 104 -127 | 128 -151 | 152 -175 | 176 -199 | 200 -223 | 224 -247 |
  # Count:     23115 |     8980 |     1213 |      990 |      780 |      172 |        9 |        0 |        0 |        0 |        0 |        0 |        0 |        0 |        0 |
  # BA miss count: 20720
  #
  # Tx Beamformer applied PPDU counts: iBF: 0, eBF: 0
  # Tx Beamformer Rx feedback statistics: All: 42, HE: 0, VHT: 42, HT: 0, BW20, NC: 104881, NR: 104881
  # Tx Beamformee successful feedback frames: 0
  # Tx Beamformee feedback triggered counts: 0
  # Tx multi-user Beamforming counts: 0
  # Tx multi-user MPDU counts: 0
  # Tx multi-user successful MPDU counts: 0
  # Tx single-user successful MPDU counts: 1154694
  #
  # Tx MSDU statistics:
  # AMSDU pack count of 1 MSDU in TXD:   982650 ( 97%)
  # AMSDU pack count of 2 MSDU in TXD:    22162 (  2%)
  # AMSDU pack count of 3 MSDU in TXD:     4933 (  0%)
  # AMSDU pack count of 4 MSDU in TXD:     1543 (  0%)
  # AMSDU pack count of 5 MSDU in TXD:      560 (  0%)
  # AMSDU pack count of 6 MSDU in TXD:      301 (  0%)
  # AMSDU pack count of 7 MSDU in TXD:      163 (  0%)
  # AMSDU pack count of 8 MSDU in TXD:      572 (  0%)

  cat /sys/kernel/debug/ieee80211/phy0/mt76/tx_stats | awk '{printf "%s=", $0} END{print ""}' |logger -p local7.info -t "stats-24-tx"
  cat /sys/kernel/debug/ieee80211/phy1/mt76/tx_stats | awk '{printf "%s=", $0} END{print ""}' |logger -p local7.info -t "stats-5-tx"
  # Wait a little
  sleep 60
done
