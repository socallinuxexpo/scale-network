#!/usr/bin/env python3
"""
CSV/TSV validation library with full parity to Perl parser.

Handles:
- Continuation lines (lines ending with ' \\')
- Comments (// and # style)
- Tab collapsing (multiple tabs -> single tab)
- Column validation with custom validators
"""

import ipaddress
import re
from os import listdir
from os.path import isfile, join

import pandas as pd


# =============================================================================
# Validator Functions
# =============================================================================


def isuntested(value):
    # pylint: disable=unused-argument
    """dummy function for untested values"""
    return True


def isvalidhostname(hostname):
    """
    test for valid short hostname with letters, numbers, and dashes
    cannot begin or end with a dash
    """
    pattern = r"^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$"
    result = re.match(pattern, hostname)
    if result:
        return True
    return False


def is_valid_asset_id(asset_id):
    """
    test for valid asset ID, which has the same constraints as a hostname
    """
    return isvalidhostname(asset_id)


def isvalidmodel(model):
    """
    test for valid switch model (enumerated)
    """
    return model in {
        "ex2200-48p",
        "ex2200-48t",
        "ex2200-24p",
        "ex2200-24t",
        "ex2300-c-12t",
        "ex2300-c-12t-vc",
        "ex2300-c-12p",
        "ex2300-c-12p-vc",
        "ex4200-24t",
        "ex4200-24p",
        "ex4200-48t",
        "ex4200-48p",
        "ex4200-48px",
        "ex4300-48t",
        "ex4300-48p",
    }


def isvalidip(addr):
    """test for valid v4 or v6 ip"""
    try:
        ipaddress.ip_address(addr)
    except ValueError:
        return False
    return True


def is_valid_v6_suffix(suffix):
    """
    test for valid v6 suffix
    """
    pattern = r"^[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4})*$"

    if not re.match(pattern, suffix):
        return False

    groups = suffix.split(":")
    return all(group and len(group) <= 4 for group in groups)


def isvalidsubnet(subnet):
    """test for valid v4 or v6 subnet"""
    try:
        ipaddress.ip_network(subnet, strict=True)
    except ValueError:
        return False
    return True


def isvalidiporempty(val):
    """test for valid ip or empty"""
    return isvalidip(val) or val == ""


def isvalidmac(macaddr):
    """test for valid colon seperate mac address"""
    pattern = r"^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$"
    result = re.match(pattern, macaddr)
    if result:
        return True
    return False


def isvalidwifi24chan(chan):
    """test for valid 2.4Ghz WiFi channel"""
    return is_non_negative_int(chan) and int(chan) in {1, 6, 11}


def isvalidwifi5chan(chan):
    """
    test for valid 5Ghz WiFi channel
    allows DFS channels
    """
    return is_non_negative_int(chan) and int(chan) in {
        32,
        36,
        40,
        44,
        48,
        52,
        56,
        60,
        64,
        100,
        104,
        108,
        112,
        116,
        120,
        124,
        128,
        132,
        136,
        140,
        144,
        149,
        153,
        157,
        161,
        165,
        169,
        173,
        177,
    }


def is_valid_pi_vlan(vlan):
    """test for valid PI vlan"""
    # we currently constrain PI use to 3 existing vlans
    # this can be extended later as needed
    return is_non_negative_int(vlan) and int(vlan) in {
        107,
        110,
        507,
    }


def is_non_negative_int(val: int | str) -> bool:
    """Test for non-negative integer (0 or greater)."""
    if isinstance(val, int):
        return val >= 0
    return val.isdigit()


def is_valid_switch_hierarchy(val: str) -> bool:
    """Test for valid switch hierarchy (e.g. ABC.1)."""
    return bool(re.match(r"^[A-Z]+\.[0-9]$", val))


def is_in_ap_list(val: str) -> bool:
    """Test for existence of serial number in aps.csv."""
    df = pd.read_csv("aps/aps.csv")
    return val in df["serial"].values


def is_valid_switch_type(val: str) -> bool:
    """test for valid switch type, denoted by existence of file in types dir"""
    type_path = "../switch-configuration/config/types/"
    valid = [f for f in listdir(type_path) if isfile(join(type_path, f))]
    return val in valid


def is_valid_map_coordinate(val: int | float | str) -> bool:
    """
    test for valid map coordinate:
    must be 0-100 and limited to 2 decimal places.
    """
    if isinstance(val, str):
        try:
            val = float(val)
        except ValueError:
            return False

    if not isinstance(val, (int, float)):
        return False

    return 0 <= val <= 100 and round(val, 2) == val


# =============================================================================
# Line Preprocessing (matches Perl read_config_file behavior)
# =============================================================================


def join_continuation_lines(lines: list[str]) -> list[str]:
    """
    Join lines ending with ' \\' (space-backslash) to the next line.
    Leading whitespace on continuation lines is stripped (matching Perl).
    """
    result = []
    current = ""
    in_continuation = False

    for line in lines:
        line = line.rstrip("\n\r")

        # Strip leading whitespace if this is a continuation line
        if in_continuation:
            line = line.lstrip()

        if line.endswith(" \\"):
            # Strip the ' \' and accumulate
            current += line[:-2] + " "
            in_continuation = True
        else:
            current += line
            result.append(current)
            current = ""
            in_continuation = False

    # Handle trailing continuation (shouldn't happen, but be safe)
    if current:
        result.append(current.rstrip())

    return result


def strip_comments(line: str) -> str:
    """Remove // and # comments from a line."""
    line = re.sub(r"//.*", "", line)
    line = re.sub(r"#.*", "", line)
    return line


def collapse_tabs(line: str) -> str:
    """Collapse multiple tabs to single tab."""
    return re.sub(r"\t+", "\t", line)


def is_blank(line: str) -> bool:
    """Check if line is empty or whitespace only."""
    return not line or line.isspace()


def preprocess_line(line: str) -> str:
    """Apply all preprocessing to a single line."""
    line = strip_comments(line)
    line = collapse_tabs(line)
    return line


def read_config_lines(filepath: str) -> list[str]:
    """
    Read and preprocess a config file.

    Args:
        filepath: Path to the config file

    Returns:
        List of preprocessed lines (no comments, tabs collapsed)
    """
    with open(filepath, encoding="utf-8") as f:
        raw_lines = f.readlines()

    # First pass: join continuation lines
    joined = join_continuation_lines(raw_lines)

    # Second pass: preprocess each line
    result = []
    for line in joined:
        line = preprocess_line(line)
        if is_blank(line):
            continue
        result.append(line)

    return result


# =============================================================================
# DataFrame Parsing and Validation
# =============================================================================


def lines_to_dataframe(lines: list[str], sep: str = "\t") -> pd.DataFrame:
    """
    Convert preprocessed lines to a DataFrame.

    Args:
        lines: Preprocessed lines (already joined, comments stripped, etc.)
        sep: Field separator (default: tab)

    Returns:
        DataFrame with string columns
    """
    if not lines:
        return pd.DataFrame()

    # Split each line and find max columns
    rows = [line.split(sep) for line in lines]
    max_cols = max(len(row) for row in rows)

    # Pad short rows with empty strings
    for row in rows:
        while len(row) < max_cols:
            row.append("")

    # Strip whitespace from all fields
    rows = [[field.strip() for field in row] for row in rows]

    return pd.DataFrame(rows)


def validate_column_count(
    df: pd.DataFrame, count: int | str, filename: str
) -> tuple[bool, str]:
    """
    Validate DataFrame has expected number of columns.

    Args:
        df: DataFrame to validate
        count: Expected column count. Use "n+" for minimum count.
        filename: Filename for error messages

    Returns:
        (success, error_message) tuple
    """
    actual = len(df.columns)

    if isinstance(count, str) and count.endswith("+"):
        min_count = int(count[:-1])
        if actual < min_count:
            return (
                False,
                f"insufficient col count: {actual} wanted {count} in {filename}",
            )
    else:
        expected = int(count)
        if actual != expected:
            return False, f"invalid col count: {actual} wanted {expected} in {filename}"

    return True, ""


def validate_dataframe(
    df: pd.DataFrame,
    validators: list,
    filename: str,
    skip_header: bool = False,
) -> tuple[bool, str]:
    """
    Apply validator functions to DataFrame columns.

    Args:
        df: DataFrame to validate
        validators: List of validator functions, one per column.
                   Use None or isuntested to skip validation for a column.
        filename: Filename for error messages
        skip_header: If True, skip the first row

    Returns:
        (success, error_message) tuple
    """
    start_row = 1 if skip_header else 0

    for row_idx in range(start_row, len(df)):
        for col_idx, validator in enumerate(validators):
            # Skip if no validator or beyond available columns
            if validator is None or col_idx >= len(df.columns):
                continue
            if validator is isuntested:
                continue

            value = df.iloc[row_idx, col_idx]

            if not validator(value):
                # Line numbers are 1-indexed for user display
                line_num = row_idx + 1
                return False, (
                    f"invalid field '{value}' failed {validator.__name__} "
                    f"at line {line_num} of {filename}"
                )

    return True, ""


# =============================================================================
# High-Level Test Functions
# =============================================================================


def test_csvfile(meta: dict) -> tuple[bool, str]:
    """
    Test a CSV file with headers.

    Args:
        meta: Dictionary with keys:
            - file: Path to CSV file
            - header: True if first row is header (skip validation)
            - count: Expected column count (int or "n+")
            - cols: List of validator functions

    Returns:
        (success, error_message) tuple
    """
    try:
        df = pd.read_csv(meta["file"], dtype=str, keep_default_na=False)
    except (FileNotFoundError, pd.errors.EmptyDataError, pd.errors.ParserError) as e:
        return False, f"failed to read {meta['file']}: {e}"

    # Validate column count
    ok, err = validate_column_count(df, meta["count"], meta["file"])
    if not ok:
        return False, err

    # Validate fields (header row is already excluded by read_csv)
    return validate_dataframe(df, meta["cols"], meta["file"], skip_header=False)


def test_tsvfile(meta: dict) -> tuple[bool, str]:
    """
    Test a TSV file (tab-separated, with Perl parser preprocessing).

    Handles continuation lines and comments.

    Args:
        meta: Dictionary with keys:
            - file: Path to TSV file
            - header: True if first row is header (skip validation)
            - count: Expected column count (int or "n+")
            - cols: List of validator functions

    Returns:
        (success, error_message) tuple
    """
    try:
        lines = read_config_lines(meta["file"])
    except (FileNotFoundError, OSError) as e:
        return False, f"failed to read {meta['file']}: {e}"

    if not lines:
        return True, ""  # Empty file is valid

    df = lines_to_dataframe(lines, sep="\t")

    # Validate column count
    ok, err = validate_column_count(df, meta["count"], meta["file"])
    if not ok:
        return False, err

    # Validate fields
    return validate_dataframe(
        df, meta["cols"], meta["file"], skip_header=meta.get("header", False)
    )
