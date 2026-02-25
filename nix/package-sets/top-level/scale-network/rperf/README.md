# rperf

This package-set installs the `rperf` rust application from [Github source](https://github.com/mfreeman451/rperf).

`rperf` is meant to be a drop-in replacement for `iperf3` and should support most of the same arguments. Below are some examples of running a server in one process and a client in another on the same host.

## Starting Server Process on Default Port

In a terminal, we can start the `rperf` server process like this:

```sh
❯ nix develop
path '/home/erik/workspace/scale-network/nix' does not contain a 'flake.nix', searching up
[nix-flakes nix] $ rperf -s
[2026-02-25T19:48:12Z INFO  rperf::server] server listening on 0.0.0.0:5199
```

## Starting a Client Test

In another process, we can spawn a client test and output the results as JSON like this:

```sh
❯ nix develop
path '/home/erik/workspace/scale-network/nix' does not contain a 'flake.nix', searching up

[nix-flakes nix] $ rperf --format json -c 0.0.0.0
[2026-02-25T19:50:06Z INFO  rperf::client] connecting to server at 0.0.0.0:5199...
[2026-02-25T19:50:06Z INFO  rperf::client] connected to server
[2026-02-25T19:50:06Z INFO  rperf::client] preparing for TCP test with 1 streams...
[2026-02-25T19:50:06Z INFO  rperf::client] informing server that testing can begin...
[2026-02-25T19:50:06Z INFO  rperf::client] waiting for server ready signal...
[2026-02-25T19:50:06Z INFO  rperf::client] server ready signal received
[2026-02-25T19:50:06Z INFO  rperf::client] beginning execution of stream 0...
[2026-02-25T19:50:16Z INFO  rperf::client] stream 0 is done
[2026-02-25T19:50:16Z INFO  rperf::client] Client streams done. Waiting for server results...
[2026-02-25T19:50:16Z INFO  rperf::client::state] Starting kill timer (5s) while waiting for server results.
[2026-02-25T19:50:16Z INFO  rperf::client] server reported completion of stream 0
[2026-02-25T19:50:16Z WARN  rperf::client::state] Client run shutdown requested.
{
  "config": {
    "additional": {
      "ip_version": 4,
      "omit_seconds": 0,
      "reverse": false
    },
    "common": {
      "family": "tcp",
      "length": 32768,
      "streams": 1
    },
    "download": {},
    "upload": {
      "bandwidth": 125000,
      "duration": 10.0,
      "no_delay": false,
      "send_interval": 0.05000000074505806
    }
  },
  "streams": [
    {
      "abandoned": false,
      "failed": false,
      "intervals": {
        "receive": [
          {
            "bytes_received": 163840,
            "duration": 1.0000245571136475,
            "timestamp": 1772049007.8585613
          },
          {
            "bytes_received": 163840,
            "duration": 1.0501344203948975,
            "timestamp": 1772049008.9087107
          },
          {
            "bytes_received": 131072,
            "duration": 1.0000648498535156,
            "timestamp": 1772049009.9087863
          },
          {
            "bytes_received": 131072,
            "duration": 1.0001791715621948,
            "timestamp": 1772049010.9089746
          },
          {
            "bytes_received": 131072,
            "duration": 1.0003045797348022,
            "timestamp": 1772049011.9092996
          },
          {
            "bytes_received": 163840,
            "duration": 1.0499694347381592,
            "timestamp": 1772049012.959289
          },
          {
            "bytes_received": 131072,
            "duration": 1.0002611875534058,
            "timestamp": 1772049013.9595702
          },
          {
            "bytes_received": 131072,
            "duration": 1.00027334690094,
            "timestamp": 1772049014.959864
          },
          {
            "bytes_received": 163840,
            "duration": 1.0498690605163574,
            "timestamp": 1772049016.009753
          }
        ],
        "send": [
          {
            "bytes_sent": 131072,
            "duration": 1.000171422958374,
            "sends_blocked": 0,
            "timestamp": 1772049007.8583403
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0000817775726318,
            "sends_blocked": 0,
            "timestamp": 1772049008.858432
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0000933408737183,
            "sends_blocked": 0,
            "timestamp": 1772049009.8585322
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0001710653305054,
            "sends_blocked": 0,
            "timestamp": 1772049010.858723
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0000975131988525,
            "sends_blocked": 0,
            "timestamp": 1772049011.858828
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0001031160354614,
            "sends_blocked": 0,
            "timestamp": 1772049012.8589518
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0001600980758667,
            "sends_blocked": 0,
            "timestamp": 1772049013.8591192
          },
          {
            "bytes_sent": 131072,
            "duration": 1.000217080116272,
            "sends_blocked": 0,
            "timestamp": 1772049014.859344
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0000717639923096,
            "sends_blocked": 0,
            "timestamp": 1772049015.8594697
          },
          {
            "bytes_sent": 131072,
            "duration": 1.0009231567382812,
            "sends_blocked": 0,
            "timestamp": 1772049016.8603995
          }
        ],
        "summary": {
          "bytes_received": 1310720,
          "bytes_sent": 1310720,
          "duration_receive": 9.15108060836792,
          "duration_send": 10.002090334892273
        }
      }
    }
  ],
  "success": true,
  "summary": {
    "bytes_received": 1310720,
    "bytes_sent": 1310720,
    "duration_receive": 9.15108060836792,
    "duration_send": 10.002090334892273
  }
}
```

If no format is specified, output looks like this:

```sh
==========
TCP send result over 10.00s | streams: 1
stream-average bytes per second: 131054.819 | megabits/second: 1.048
total bytes: 1310720 | per second: 131054.819 | megabits/second: 1.048
==========
TCP receive result over 10.00s | streams: 1
stream-average bytes per second: 131053.152 | megabits/second: 1.048
total bytes: 1310720 | per second: 131053.152 | megabits/second: 1.048
```

Back in the **server** process, we can see log messages showing the client connection and a test-run started:

```sh
[2026-02-25T19:49:46Z INFO  rperf::server] connection from 127.0.0.1:46136
[2026-02-25T19:49:46Z INFO  rperf::server] [127.0.0.1:46136] running in forward-mode: server will be receiving data
[2026-02-25T19:49:46Z INFO  rperf::server] [127.0.0.1:46136] preparing for TCP test with 1 streams...
[2026-02-25T19:49:46Z INFO  rperf::server] [127.0.0.1:46136] beginning execution of stream 0...
[2026-02-25T19:49:46Z INFO  rperf::server] [127.0.0.1:46136] receiver threads spawned, sending ready signal
[2026-02-25T19:49:56Z INFO  rperf::server] [127.0.0.1:46136] end of testing signaled
[2026-02-25T19:49:56Z INFO  rperf::server] 127.0.0.1:46136 disconnected
[2026-02-25T19:50:06Z INFO  rperf::server] connection from 127.0.0.1:45022
[2026-02-25T19:50:06Z INFO  rperf::server] [127.0.0.1:45022] running in forward-mode: server will be receiving data
[2026-02-25T19:50:06Z INFO  rperf::server] [127.0.0.1:45022] preparing for TCP test with 1 streams...
[2026-02-25T19:50:06Z INFO  rperf::server] [127.0.0.1:45022] beginning execution of stream 0...
[2026-02-25T19:50:06Z INFO  rperf::server] [127.0.0.1:45022] receiver threads spawned, sending ready signal
[2026-02-25T19:50:16Z INFO  rperf::server] [127.0.0.1:45022] end of testing signaled
[2026-02-25T19:50:16Z INFO  rperf::server] 127.0.0.1:45022 disconnected
^C[2026-02-25T19:54:39Z WARN  rperf::server::state] Server shutdown requested.
```
