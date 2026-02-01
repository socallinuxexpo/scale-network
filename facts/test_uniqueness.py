#!/usr/bin/env python3
"""
Tests for cross-file uniqueness validation.
"""

import pandas as pd

import datasource as ds
from uniqueness import UniquenessRegistry


# =============================================================================
# Helper Functions
# =============================================================================


def check_reference(
    child: tuple[pd.DataFrame, int, str],
    parent: tuple[pd.DataFrame, int, str],
) -> tuple[bool, str]:
    """
    Check that all values in child column exist in parent column.

    Args:
        child: Tuple of (DataFrame, column_index, filename)
        parent: Tuple of (DataFrame, column_index, filename)

    Returns:
        (ok, error_message) tuple
    """
    child_df, child_col, child_file = child
    parent_df, parent_col, parent_file = parent

    child_values = set(child_df.iloc[:, child_col])
    parent_values = set(parent_df.iloc[:, parent_col])

    # Remove empty strings
    child_values.discard("")
    parent_values.discard("")

    missing = child_values - parent_values
    if missing:
        return False, (
            f"values in {child_file} column {child_col} "
            f"not found in {parent_file} column {parent_col}: {sorted(missing)}"
        )

    return True, ""


# =============================================================================
# Internal Unit Tests
# =============================================================================


def test_no_collisions():
    """Registry with no collisions should pass check."""
    reg = UniquenessRegistry()
    reg.register("hostname", "server1", "servers.csv")
    reg.register("hostname", "server2", "servers.csv")
    reg.register("hostname", "router1", "routers.csv")

    ok, err = reg.check()
    assert ok
    assert err == ""


def test_inter_file_collision():
    """Same value in different files should be detected."""
    reg = UniquenessRegistry()
    reg.register("hostname", "device1", "servers.csv")
    reg.register("hostname", "device1", "routers.csv")

    ok, err = reg.check()
    assert not ok
    assert "hostname:device1" in err
    assert "servers.csv" in err
    assert "routers.csv" in err


def test_intra_file_collision():
    """Duplicate value within same file should be detected."""
    reg = UniquenessRegistry()
    reg.register("hostname", "server1", "servers.csv")
    reg.register("hostname", "server1", "servers.csv")

    ok, err = reg.check()
    assert not ok
    assert "hostname:server1" in err
    assert "(x2)" in err


def test_empty_values_skipped():
    """Empty values should not be considered duplicates."""
    reg = UniquenessRegistry()
    reg.register("ipv4", "", "servers.csv")
    reg.register("ipv4", "", "routers.csv")

    ok, _ = reg.check()
    assert ok


def test_multiple_field_types():
    """Collisions should be tracked per field type."""
    reg = UniquenessRegistry()
    reg.register("hostname", "device1", "servers.csv")
    reg.register("mac", "00:11:22:33:44:55", "servers.csv")
    reg.register("hostname", "device2", "routers.csv")
    reg.register("mac", "00:11:22:33:44:55", "routers.csv")  # collision

    ok, err = reg.check()
    assert not ok
    assert "mac:00:11:22:33:44:55" in err
    assert "hostname:device1" not in err  # no collision on hostname


def test_check_specific_field_type():
    """Check can be limited to a specific field type."""
    reg = UniquenessRegistry()
    reg.register("hostname", "device1", "servers.csv")
    reg.register("hostname", "device1", "routers.csv")  # collision
    reg.register("mac", "aa:bb:cc:dd:ee:ff", "servers.csv")

    # Check only mac - should pass
    ok, _ = reg.check("mac")
    assert ok

    # Check only hostname - should fail
    ok, _ = reg.check("hostname")
    assert not ok


def test_register_column():
    """Register column should track all values from a DataFrame column."""
    reg = UniquenessRegistry()
    df = pd.DataFrame([["host1", "mac1"], ["host2", "mac2"], ["host1", "mac3"]])

    reg.register_column("hostname", df, 0, "test.csv")

    ok, err = reg.check()
    assert not ok
    assert "hostname:host1" in err


def test_register_column_out_of_range():
    """Register column with out-of-range index should be ignored."""
    reg = UniquenessRegistry()
    df = pd.DataFrame([["host1", "mac1"]])

    # Should not raise, just skip
    reg.register_column("hostname", df, 5, "test.csv")

    ok, _ = reg.check()
    assert ok


def test_clear():
    """Clear should reset all registered values."""
    reg = UniquenessRegistry()
    reg.register("hostname", "device1", "servers.csv")
    reg.register("hostname", "device1", "routers.csv")

    reg.clear()

    ok, _ = reg.check()
    assert ok


def test_get_collisions_returns_dict():
    """Get collisions should return dict of value to sources."""
    reg = UniquenessRegistry()
    reg.register("hostname", "device1", "servers.csv")
    reg.register("hostname", "device1", "routers.csv")

    collisions = reg.get_collisions()
    assert "hostname:device1" in collisions
    assert set(collisions["hostname:device1"]) == {"servers.csv", "routers.csv"}


def test_check_reference_valid():
    """Check reference should pass when all child values exist in parent."""
    parent = pd.DataFrame([["a"], ["b"], ["c"]])
    child = pd.DataFrame([["a"], ["b"]])

    ok, _ = check_reference(
        (child, 0, "child.csv"),
        (parent, 0, "parent.csv"),
    )
    assert ok


def test_check_reference_missing():
    """Check reference should fail when child values missing from parent."""
    parent = pd.DataFrame([["a"], ["b"]])
    child = pd.DataFrame([["a"], ["c"], ["d"]])

    ok, err = check_reference(
        (child, 0, "child.csv"),
        (parent, 0, "parent.csv"),
    )
    assert not ok
    assert "c" in err
    assert "d" in err


def test_check_reference_empty_skipped():
    """Check reference should skip empty values."""
    parent = pd.DataFrame([["a"], ["b"]])
    child = pd.DataFrame([["a"], [""]])

    ok, _ = check_reference(
        (child, 0, "child.csv"),
        (parent, 0, "parent.csv"),
    )
    assert ok


# =============================================================================
# Integration Tests - Intra-file Uniqueness (replaces test_duplicates.fish)
# =============================================================================


def load_switchtypes():
    """Load switchtypes TSV file using datasource preprocessing."""
    lines = ds.read_config_lines("../switch-configuration/config/switchtypes")
    return ds.lines_to_dataframe(lines, sep="\t")


def test_switchtypes_uniqueness():
    """Ensure no duplicates within switchtypes (name, ipv6, mac)."""
    reg = UniquenessRegistry()
    df = load_switchtypes()
    reg.register_column("name", df, 0, "switchtypes")
    reg.register_column("num", df, 1, "switchtypes")
    reg.register_column("ipv6", df, 3, "switchtypes")
    reg.register_column("mac", df, 8, "switchtypes")

    ok, err = reg.check()
    assert ok, err


def test_aps_csv_uniqueness():
    """Ensure no duplicates within aps.csv (serial, mac)."""
    reg = UniquenessRegistry()
    df = pd.read_csv("./aps/aps.csv", dtype=str, keep_default_na=False)
    reg.register_column("serial", df, 0, "./aps/aps.csv")
    reg.register_column("mac", df, 1, "./aps/aps.csv")

    ok, err = reg.check()
    assert ok, err


def test_apuse_csv_uniqueness():
    """Ensure no duplicates within apuse.csv (name, serial, ipv4)."""
    reg = UniquenessRegistry()
    df = pd.read_csv("./aps/apuse.csv", dtype=str, keep_default_na=False)
    reg.register_column("name", df, 0, "./aps/apuse.csv")
    reg.register_column("serial", df, 1, "./aps/apuse.csv")
    reg.register_column("ipv4", df, 2, "./aps/apuse.csv")

    ok, err = reg.check()
    assert ok, err


def test_pis_csv_uniqueness():
    """Ensure no duplicates within pis.csv (serial, mac)."""
    reg = UniquenessRegistry()
    df = pd.read_csv("./pi/pis.csv", dtype=str, keep_default_na=False)
    reg.register_column("serial", df, 0, "./pi/pis.csv")
    reg.register_column("mac", df, 1, "./pi/pis.csv")
    reg.register_column("v6suffix", df, 2, "./pi/pis.csv")

    ok, err = reg.check()
    assert ok, err


def test_piuse_csv_uniqueness():
    """Ensure no duplicates within piuse.csv (name, serial)."""
    reg = UniquenessRegistry()
    df = pd.read_csv("./pi/piuse.csv", dtype=str, keep_default_na=False)
    reg.register_column("name", df, 0, "./pi/piuse.csv")
    reg.register_column("serial", df, 1, "./pi/piuse.csv")

    ok, err = reg.check()
    assert ok, err


def test_routerlist_csv_uniqueness():
    """Ensure no duplicates within routerlist.csv (name, ipv6)."""
    reg = UniquenessRegistry()
    df = pd.read_csv("./routers/routerlist.csv", dtype=str, keep_default_na=False)
    reg.register_column("name", df, 0, "./routers/routerlist.csv")
    reg.register_column("ipv6", df, 1, "./routers/routerlist.csv")

    ok, err = reg.check()
    assert ok, err


def test_serverlist_csv_uniqueness():
    """Ensure no duplicates within serverlist.csv (name, mac, ipv6, ipv4)."""
    reg = UniquenessRegistry()
    df = pd.read_csv("./servers/serverlist.csv", dtype=str, keep_default_na=False)
    reg.register_column("name", df, 0, "./servers/serverlist.csv")
    reg.register_column("mac", df, 1, "./servers/serverlist.csv")
    reg.register_column("ipv6", df, 2, "./servers/serverlist.csv")
    reg.register_column("ipv4", df, 3, "./servers/serverlist.csv")

    ok, err = reg.check()
    assert ok, err


# =============================================================================
# Integration Tests - Inter-file Uniqueness (GitHub issue: naming collisions)
# =============================================================================


def test_hostname_uniqueness_across_files():
    """Ensure hostnames are unique across all device types."""
    reg = UniquenessRegistry()

    # CSV files
    hostname_sources = [
        ("./aps/apuse.csv", 0),
        ("./pi/piuse.csv", 0),
        ("./servers/serverlist.csv", 0),
        ("./routers/routerlist.csv", 0),
    ]
    for filepath, col_idx in hostname_sources:
        df = pd.read_csv(filepath, dtype=str, keep_default_na=False)
        reg.register_column("hostname", df, col_idx, filepath)

    # Switches (TSV)
    switch_df = load_switchtypes()
    reg.register_column("hostname", switch_df, 0, "switchtypes")

    ok, err = reg.check()
    assert ok, err


def test_mac_uniqueness_across_files():
    """Ensure MAC addresses are unique across all hardware."""
    reg = UniquenessRegistry()

    # CSV files
    mac_sources = [
        ("./aps/aps.csv", 1),
        ("./servers/serverlist.csv", 1),
        ("./pi/pis.csv", 1),
    ]
    for filepath, col_idx in mac_sources:
        df = pd.read_csv(filepath, dtype=str, keep_default_na=False)
        reg.register_column("mac", df, col_idx, filepath)

    # Switches (TSV)
    switch_df = load_switchtypes()
    reg.register_column("mac", switch_df, 8, "switchtypes")

    ok, err = reg.check()
    assert ok, err


def test_ipv4_uniqueness_across_files():
    """Ensure IPv4 addresses are unique across all devices."""
    reg = UniquenessRegistry()

    ipv4_sources = [
        ("./aps/apuse.csv", 2),
        ("./servers/serverlist.csv", 3),
    ]
    for filepath, col_idx in ipv4_sources:
        df = pd.read_csv(filepath, dtype=str, keep_default_na=False)
        reg.register_column("ipv4", df, col_idx, filepath)

    ok, err = reg.check()
    assert ok, err


def test_ipv6_uniqueness_across_files():
    """Ensure IPv6 addresses are unique across all devices."""
    reg = UniquenessRegistry()

    # CSV files
    ipv6_sources = [
        ("./servers/serverlist.csv", 2),
        ("./routers/routerlist.csv", 1),
    ]
    for filepath, col_idx in ipv6_sources:
        df = pd.read_csv(filepath, dtype=str, keep_default_na=False)
        reg.register_column("ipv6", df, col_idx, filepath)

    # Switches (TSV)
    switch_df = load_switchtypes()
    reg.register_column("ipv6", switch_df, 3, "switchtypes")

    ok, err = reg.check()
    assert ok, err


# =============================================================================
# Integration Tests - Referential Integrity
# =============================================================================


def test_apuse_references_aps():
    """Ensure all serials in apuse.csv exist in aps.csv."""
    aps_df = pd.read_csv("./aps/aps.csv", dtype=str, keep_default_na=False)
    apuse_df = pd.read_csv("./aps/apuse.csv", dtype=str, keep_default_na=False)

    ok, err = check_reference(
        (apuse_df, 1, "./aps/apuse.csv"),
        (aps_df, 0, "./aps/aps.csv"),
    )
    assert ok, err


def test_piuse_references_pis():
    """Ensure all serials in piuse.csv exist in pis.csv."""
    pis_df = pd.read_csv("./pi/pis.csv", dtype=str, keep_default_na=False)
    piuse_df = pd.read_csv("./pi/piuse.csv", dtype=str, keep_default_na=False)

    ok, err = check_reference(
        (piuse_df, 1, "./pi/piuse.csv"),
        (pis_df, 0, "./pi/pis.csv"),
    )
    assert ok, err
