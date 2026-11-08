# Bulk Ethernet Cable Testing

**Technical contacts:** Rob, Ryan, and Owen

**Platform:** Juniper EX4300 with 48 RJ-45 access ports (for example, EX4300-48T or EX4300-48P)

## Purpose

This procedure describes how to perform **bulk, preliminary copper Ethernet cable diagnostics** using the time-domain reflectometry (TDR) functionality built into a Juniper EX4300 switch. It is intended for nonprofit equipment preparation and cable troubleshooting, including work performed by volunteers under supervision.

TDR can identify likely open circuits, shorts, and impedance mismatches in individual twisted pairs, and may estimate the distance from the testing switch to a fault. **TDR is not a substitute for a dedicated cable certifier**, and a successful test does not certify a cable for a particular Ethernet category, bandwidth, or PoE application.

## Responsibilities and access

- **Rob, Ryan, or Owen** can conduct the tests or coordinate a testing session.
- Volunteers must not alter the switch configuration or perform tests on interfaces that carry active services.

## Equipment and prerequisites

- A Juniper EX4300 with RJ-45 copper access ports and an authorized operational-mode CLI session.
- Up to 48 Ethernet cables to be tested, with unique labels or an unambiguous port-to-cable mapping.
- A known-good reference cable for a preliminary control test.
- A spare switch or other coordinator-approved far-end reference arrangement, if required for the local testing method.

> **Safety and accuracy:** Juniper documents TDR as a test to trigger when the **link is down** and traffic is **nil**. The **testing interface must remain administratively enabled**; administratively disabled ports cannot run TDR. This project used a spare switch as the far-end connection, and the supplied field logs include successful TDR executions reporting `Link status: UP`. That observation does **not** remove the manufacturer's link-down/no-traffic caution or prove a live-link result is reliable. Only use the isolated, coordinator-approved testing arrangement, with no production traffic; have a technical contact validate the baseline and any link-up results before accepting a cable. TDR measurements can be affected by the remote device and PHY behavior.

The complete command list below assumes a 48-port model using interfaces `ge-0/0/0` through `ge-0/0/47` (FPC/member 0). For 24-port models, virtual chassis members, or other EX4300 variants, verify actual interface names and use only supported **RJ-45 copper** ports. TDR does not apply to the switch's management or SFP/fiber interfaces.

## Procedure

### 1. Prepare and label the cables

1. Confirm that the designated EX4300 is a **test switch**, not a switch carrying production traffic.
1. Label each cable and document which cable is connected to each EX4300 interface. Record the far-end connection if applicable.
1. Attach the cables to the EX4300 RJ-45 ports. In the original workflow, a **spare switch was used at the opposite end** of the cables. Match each cable to its expected spare-switch port and confirm that both RJ-45 plugs are fully seated. The coordinator must confirm the far-end setup is safe and suitable for TDR testing.
1. Verify that the target testing ports are administratively enabled and **not passing traffic**.
1. Perform one trial on a **known-good cable** and check the output before testing the remaining cables. If its results look inconsistent, stop and ask a technical contact to verify the setup.

### 2. Log in to the switch

Connect to the switch using the console or approved SSH access supplied by a coordinator. The commands in this guide are run from the Junos **operational-mode prompt** (`>`), not configuration mode (`#`).

Optionally check the interfaces before proceeding:

```text
show interfaces terse | match ge-0/0/
```

### 3. Run an initial single-port test

Start a TDR diagnostic on the known-good cable connected to `ge-0/0/0` (or a different designated test port):

```text
request diagnostics tdr start interface ge-0/0/0
```

The command starts the diagnostic. The provided terminal transcript shows the switch replying `Test successfully executed` to each of the 48 start commands. This message confirms that a diagnostic was initiated, not that the associated cable is healthy. Inspect the result after it completes:

```text
show diagnostics tdr interface ge-0/0/0
```

If `Test status` shows `Started`, allow the test to finish and check again. Check **each MDI pair's `Cable status`**, not just `Test status`.

### 4. Start TDR diagnostics on all 48 ports

Once the control test is satisfactory, paste the commands below at the Junos operational-mode prompt. To keep the output manageable, it is reasonable to paste them in smaller groups and verify that the switch accepts each command.

```text
request diagnostics tdr start interface ge-0/0/0
request diagnostics tdr start interface ge-0/0/1
request diagnostics tdr start interface ge-0/0/2
request diagnostics tdr start interface ge-0/0/3
request diagnostics tdr start interface ge-0/0/4
request diagnostics tdr start interface ge-0/0/5
request diagnostics tdr start interface ge-0/0/6
request diagnostics tdr start interface ge-0/0/7
request diagnostics tdr start interface ge-0/0/8
request diagnostics tdr start interface ge-0/0/9
request diagnostics tdr start interface ge-0/0/10
request diagnostics tdr start interface ge-0/0/11
request diagnostics tdr start interface ge-0/0/12
request diagnostics tdr start interface ge-0/0/13
request diagnostics tdr start interface ge-0/0/14
request diagnostics tdr start interface ge-0/0/15
request diagnostics tdr start interface ge-0/0/16
request diagnostics tdr start interface ge-0/0/17
request diagnostics tdr start interface ge-0/0/18
request diagnostics tdr start interface ge-0/0/19
request diagnostics tdr start interface ge-0/0/20
request diagnostics tdr start interface ge-0/0/21
request diagnostics tdr start interface ge-0/0/22
request diagnostics tdr start interface ge-0/0/23
request diagnostics tdr start interface ge-0/0/24
request diagnostics tdr start interface ge-0/0/25
request diagnostics tdr start interface ge-0/0/26
request diagnostics tdr start interface ge-0/0/27
request diagnostics tdr start interface ge-0/0/28
request diagnostics tdr start interface ge-0/0/29
request diagnostics tdr start interface ge-0/0/30
request diagnostics tdr start interface ge-0/0/31
request diagnostics tdr start interface ge-0/0/32
request diagnostics tdr start interface ge-0/0/33
request diagnostics tdr start interface ge-0/0/34
request diagnostics tdr start interface ge-0/0/35
request diagnostics tdr start interface ge-0/0/36
request diagnostics tdr start interface ge-0/0/37
request diagnostics tdr start interface ge-0/0/38
request diagnostics tdr start interface ge-0/0/39
request diagnostics tdr start interface ge-0/0/40
request diagnostics tdr start interface ge-0/0/41
request diagnostics tdr start interface ge-0/0/42
request diagnostics tdr start interface ge-0/0/43
request diagnostics tdr start interface ge-0/0/44
request diagnostics tdr start interface ge-0/0/45
request diagnostics tdr start interface ge-0/0/46
request diagnostics tdr start interface ge-0/0/47
```

**Important:** A message saying the test was successfully executed means the test was **started**, not that the cable passed inspection. Some diagnostics may need a few seconds to finish.

### 5. Review the results (interface required in this SOP)

**Always specify an interface when displaying TDR results for this workflow.** The supported, tested command pattern is:

```text
show diagnostics tdr interface ge-0/0/xx
```

Replace `xx` with the port number (0 through 47); do not type `xx` literally. For example:

```text
show diagnostics tdr interface ge-0/0/12
```

For bulk verification, paste the following **48 separate interface-specific commands** at the Junos operational-mode prompt. Reviewing every interface is necessary because successful `request` responses alone do not show cable condition.

```text
show diagnostics tdr interface ge-0/0/0
show diagnostics tdr interface ge-0/0/1
show diagnostics tdr interface ge-0/0/2
show diagnostics tdr interface ge-0/0/3
show diagnostics tdr interface ge-0/0/4
show diagnostics tdr interface ge-0/0/5
show diagnostics tdr interface ge-0/0/6
show diagnostics tdr interface ge-0/0/7
show diagnostics tdr interface ge-0/0/8
show diagnostics tdr interface ge-0/0/9
show diagnostics tdr interface ge-0/0/10
show diagnostics tdr interface ge-0/0/11
show diagnostics tdr interface ge-0/0/12
show diagnostics tdr interface ge-0/0/13
show diagnostics tdr interface ge-0/0/14
show diagnostics tdr interface ge-0/0/15
show diagnostics tdr interface ge-0/0/16
show diagnostics tdr interface ge-0/0/17
show diagnostics tdr interface ge-0/0/18
show diagnostics tdr interface ge-0/0/19
show diagnostics tdr interface ge-0/0/20
show diagnostics tdr interface ge-0/0/21
show diagnostics tdr interface ge-0/0/22
show diagnostics tdr interface ge-0/0/23
show diagnostics tdr interface ge-0/0/24
show diagnostics tdr interface ge-0/0/25
show diagnostics tdr interface ge-0/0/26
show diagnostics tdr interface ge-0/0/27
show diagnostics tdr interface ge-0/0/28
show diagnostics tdr interface ge-0/0/29
show diagnostics tdr interface ge-0/0/30
show diagnostics tdr interface ge-0/0/31
show diagnostics tdr interface ge-0/0/32
show diagnostics tdr interface ge-0/0/33
show diagnostics tdr interface ge-0/0/34
show diagnostics tdr interface ge-0/0/35
show diagnostics tdr interface ge-0/0/36
show diagnostics tdr interface ge-0/0/37
show diagnostics tdr interface ge-0/0/38
show diagnostics tdr interface ge-0/0/39
show diagnostics tdr interface ge-0/0/40
show diagnostics tdr interface ge-0/0/41
show diagnostics tdr interface ge-0/0/42
show diagnostics tdr interface ge-0/0/43
show diagnostics tdr interface ge-0/0/44
show diagnostics tdr interface ge-0/0/45
show diagnostics tdr interface ge-0/0/46
show diagnostics tdr interface ge-0/0/47
```

The Juniper command reference also documents a no-interface summary form and, on some software releases, a range form. **This SOP intentionally does not use either**: the field procedure requires an explicit interface for every result query. Do not rely on commands copied from a different platform or software version. If any port returns `Started`, wait and query that **same interface** again; if it returns `Not Started`, rerun its start command and review again.

## Interpreting TDR output

| Field or value | Interpretation | Recommended action |
| --- | --- | --- |
| `Test status: Passed` | The diagnostic completed successfully; **not** a guarantee of a good cable. | Check `Cable status` for all four pairs. |
| `Cable status: Normal` (per pair) | No fault was detected on that pair. | Inspect the other three pairs. |
| `Open` | A pair may be disconnected or broken. | Verify connectors, far-end conditions, and cable integrity; retest. |
| `Short on Pair-n` | A short was detected on a twisted pair. | Remove the cable from service pending inspection/replacement and retest. |
| `Impedance Mismatch` | Possible damage, improper termination, or connector issue. | Inspect and retest with a verified reference setup. |
| `Distance fault` | Approximate distance in meters from the testing interface to the detected fault. | Use as a troubleshooting estimate, not a precise measurement. |
| `Not Started`, `Started`, or `Failed` | Missing, incomplete, or unsuccessful diagnostic. | Retry or escalate; do not mark the cable good. |
| `Admin Down` or `VCT not supported` | The testing interface is disabled or does not support the test. | Ask a coordinator to check the interface and switch model. |

**Example:** In the provided terminal capture, `ge-0/0/12` reported `Test status: Passed`, but all four pairs reported `Open` at `0 Meters` and the link was `Down`. A later measurement of the same port reported all pairs `Normal` with the link `UP`. This reinforces that **test completion is not a cable pass**, and that the connector/far-end state can change between runs.

## Example results and failure modes

The first four examples below are **abridged excerpts from the provided real switch transcript**, retaining the actual interface, link state, pair status, and fault-distance values while omitting fields such as polarity and skew. They are snapshots, **not a certification or proof of the ultimate cause**. Example 5 is **illustrative only** and was not observed in the provided session.

### Example 1: Four normal pairs (observed on `ge-0/0/46`)

```text
root> show diagnostics tdr interface ge-0/0/46
Interface TDR detail:
Interface name                  : ge-0/0/46
Test status                     : Passed
Link status                     :  UP
MDI pair                        : 1-2
  Cable status                  : Normal
  Distance fault                : 0 Meters
MDI pair                        : 3-6
  Cable status                  : Normal
  Distance fault                : 0 Meters
MDI pair                        : 4-5
  Cable status                  : Normal
  Distance fault                : 0 Meters
MDI pair                        : 7-8
  Cable status                  : Normal
  Distance fault                : 0 Meters
```

**Meaning:** The completed test detected no pair-level faults. This is a good *screening* result under the original far-end setup, but `Link status: UP` should be interpreted in light of Juniper's documented link-down test caution. Record `TDR OK` only after the technical contact accepts the baseline.

### Example 2: All pairs open at approximately the same cable length (observed on `ge-0/0/8`)

```text
root> show diagnostics tdr interface ge-0/0/8
Interface TDR detail:
Interface name                  : ge-0/0/8
Test status                     : Passed
Link status                     : Down
MDI pair                        : 1-2
  Cable status                  : Open
  Distance fault                : 9 Meters
MDI pair                        : 3-6
  Cable status                  : Open
  Distance fault                : 9 Meters
MDI pair                        : 4-5
  Cable status                  : Open
  Distance fault                : 9 Meters
MDI pair                        : 7-8
  Cable status                  : Open
  Distance fault                : 9 Meters
```

**Likely first check in this setup:** The RJ-45 plug may **not be fully seated in the terminating spare switch**, or the remote port may not be connected at all. When all four pairs are open at effectively the same distance, check the far-end plug and port mapping **before assuming the cable is damaged**. In the provided transcript, a later test of `ge-0/0/8` showed `Link status: UP` and all four pairs `Normal` after another test run. The logs do not establish which physical action changed the result.

### Example 3: All pairs open within 1 meter of each other (observed on `ge-0/0/34`)

```text
root> show diagnostics tdr interface ge-0/0/34
Interface TDR detail:
Interface name                  : ge-0/0/34
Test status                     : Passed
Link status                     : Down
MDI pair                        : 1-2
  Cable status                  : Open
  Distance fault                : 8 Meters
MDI pair                        : 3-6
  Cable status                  : Open
  Distance fault                : 7 Meters
MDI pair                        : 4-5
  Cable status                  : Open
  Distance fault                : 7 Meters
MDI pair                        : 7-8
  Cable status                  : Open
  Distance fault                : 8 Meters
```

**Meaning:** The 7–8 meter cluster is consistent with a common far-end termination/connection issue. Reseat the plug at the spare switch, confirm the correct remote port, and rerun `request diagnostics tdr start interface ge-0/0/34` followed by the interface-specific `show` command. Small differences between pair readings are not a definitive sign of faults in four separate places.

### Example 4: All pairs open at 0 meters (observed on `ge-0/0/12` and `ge-0/0/20`)

```text
root> show diagnostics tdr interface ge-0/0/12
Interface TDR detail:
Interface name                  : ge-0/0/12
Test status                     : Passed
Link status                     : Down
MDI pair                        : 1-2
  Cable status                  : Open
  Distance fault                : 0 Meters
MDI pair                        : 3-6
  Cable status                  : Open
  Distance fault                : 0 Meters
MDI pair                        : 4-5
  Cable status                  : Open
  Distance fault                : 0 Meters
MDI pair                        : 7-8
  Cable status                  : Open
  Distance fault                : 0 Meters
```

**Meaning:** Investigate the test-switch-side plug, local port, and whether a cable is actually connected. A 0-meter estimate should **not** be read as an exact fault location; it can also reflect measurement limits or an unsuitable test arrangement. In the transcript, `ge-0/0/12` later returned normal pairs with the link up. Do not permanently reject a cable until the connection and test are repeated.

### Example 5: Single-pair open, short, or impedance mismatch (illustrative patterns only)

The supplied session **does not** contain a captured single-pair open, short, or impedance-mismatch result. The following fragments show the *types of fields* to watch for, based on Juniper's documented `Cable status` values; they are **not literal switch output from this testing session**.

```text
# Illustrative: one pair open while other pairs are Normal
MDI pair                        : 4-5
  Cable status                  : Open
  Distance fault                : 3 Meters

# Illustrative: a short reported on a pair
MDI pair                        : 3-6
  Cable status                  : Short on Pair-2
  Distance fault                : 4 Meters

# Illustrative: an impedance mismatch
MDI pair                        : 1-2
  Cable status                  : Impedance Mismatch
  Distance fault                : 2 Meters
```

In Juniper documentation, the label `Short on Pair-n` uses `n` as a placeholder; the illustrative `Pair-2` above is a possible numeric substitution, **not a status observed in the supplied logs**. Any of these findings warrants checking both connectors and the cable, then rerunning the test. If the problem persists, set the cable aside for repair, replacement, or confirmation with a dedicated tester.

### Quick first-check guide

| Observed pattern | First likely explanation to check | Recommended next action |
| --- | --- | --- |
| `Normal` on all four pairs | No TDR-detected fault under the current setup | Record result; confirm acceptable baseline and link conditions. |
| All four pairs `Open` at nearly the same nonzero distance | Remote/far-end plug not fully seated, unplugged, or common termination problem | Check the spare-switch end first, reseat, retest. |
| All four pairs `Open` at `0 Meters` | Local plug disconnected/not seated or inconclusive near-end reading | Check EX4300 end and port mapping; retest. |
| Only one pair `Open` | Damaged conductor, poor crimp, or single-pair termination fault | Inspect/replace connectors; retest and set aside if persistent. |
| Any `Short on Pair-n` | Conductors touching or termination damage | Remove cable from accepted batch; inspect/replace and retest. |
| `Impedance Mismatch` | Possible cable damage or connector/termination quality problem | Compare with known-good cable and confirm with another tester. |
| `Test status: Passed` alongside `Open` | The diagnostic completed and **found a fault condition** | Do not classify as passing; troubleshoot and retest. |

## Troubleshooting and escalation

| Symptom | What to check |
| --- | --- |
| The link is `UP` before testing | The supplied EX4300 log includes UP/Normal results, but Juniper documents testing with the physical link down and nil traffic. Verify isolation and ask a coordinator to approve how to interpret this setup; never test a live production connection. |
| The diagnostic returns `Admin Down` | The local testing port is administratively disabled. A coordinator must confirm an appropriate enabled, link-down test arrangement. |
| The port reports `VCT not supported` | Verify that it is a supported RJ-45 network interface, not a management, optical, or unsupported interface. |
| A result remains `Started` | Allow more time and rerun the `show` command. Escalate if it does not complete. |
| Known-good cables are reported as faulty | Stop the batch and verify the spare-switch termination setup, connection mapping, reference cable, and interface state. |
| All four pairs show `Open` at approximately the same cable length | Check that the connector is **fully clicked into the spare termination switch**, and that the cable is mapped to the intended port; then rerun the test. |
| Some cables show defects | Inspect connectors and patch points, then repeat the TDR test. Use a dedicated cable tester/certifier when stronger validation is needed. |

To abort a currently running test on one port, a coordinator may use:

```text
request diagnostics tdr abort interface ge-0/0/12
```

Aborting a test clears its previous TDR results; only use this when necessary.

## Completion checklist

- [ ] The known-good control test behaved as expected.
- [ ] Testing took place on approved, isolated, idle copper links; any link-up test results were reviewed against Juniper's documented precautions.
- [ ] Each intended port was reviewed with an explicit `show diagnostics tdr interface ge-0/0/N` command and has a completed TDR result or an `Inconclusive` disposition.
- [ ] Cables requiring inspection or retesting have been separated and labeled.
- [ ] Rob, Ryan, or Owen has been notified of unresolved or ambiguous results.

## References

- [Juniper: Diagnose a Faulty Twisted-Pair Cable (CLI Procedure)](https://www.juniper.net/documentation/us/en/software/junos/interfaces-ethernet-switches/topics/topic-map/diagnose-faulty-twisted-pair-cable.html)
- [Juniper: `request diagnostics tdr` command reference](https://www.juniper.net/documentation/us/en/software/junos/cli-reference/topics/ref/command/request-diagnostics-tdr.html)
- [Juniper: `show diagnostics tdr` command reference](https://www.juniper.net/documentation/us/en/software/junos/cli-reference/topics/ref/command/show-diagnostics-tdr.html) (vendor syntax may allow summary/range forms; this local SOP requires an explicit interface)
- [Juniper: EX4300 System Overview](https://www.juniper.net/documentation/us/en/hardware/ex4300/topics/topic-map/ex4300-system-overview.html)
