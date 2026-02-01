#!/usr/bin/env python3
"""
Cross-file uniqueness validation.

Tracks values across multiple data files to detect collisions
(e.g., duplicate hostnames, MAC addresses, IPs across different sources).
"""

import pandas as pd


class UniquenessRegistry:
    """Track values across files to detect collisions."""

    def __init__(self):
        # {field_type: {value: [source1, source2, ...]}}
        self._seen: dict[str, dict[str, list[str]]] = {}

    def register(self, field_type: str, value: str, source: str) -> None:
        """Register a value, tracking where it came from."""
        if not value:  # skip empty
            return
        if field_type not in self._seen:
            self._seen[field_type] = {}
        if value not in self._seen[field_type]:
            self._seen[field_type][value] = []
        self._seen[field_type][value].append(source)

    def register_column(
        self, field_type: str, df: pd.DataFrame, col_idx: int, source: str
    ) -> None:
        """Register all values in a DataFrame column."""
        if col_idx >= len(df.columns):
            return
        for value in df.iloc[:, col_idx]:
            self.register(field_type, value, source)

    def get_collisions(self, field_type: str = None) -> dict[str, list[str]]:
        """
        Return values that appear multiple times.

        Detects both:
        - Inter-file collisions: same value in different files
        - Intra-file collisions: same value repeated in one file
        """
        collisions = {}
        types_to_check = [field_type] if field_type else list(self._seen.keys())

        for ftype in types_to_check:
            if ftype not in self._seen:
                continue
            for value, sources in self._seen[ftype].items():
                unique_sources = list(set(sources))
                if len(unique_sources) > 1:
                    # Inter-file collision
                    collisions[f"{ftype}:{value}"] = unique_sources
                elif len(sources) > 1:
                    # Intra-file collision (duplicate within same file)
                    collisions[f"{ftype}:{value}"] = [f"{sources[0]} (x{len(sources)})"]

        return collisions

    def check(self, field_type: str = None) -> tuple[bool, str]:
        """
        Check for collisions.

        Args:
            field_type: Optional field type to check. If None, checks all.

        Returns:
            (ok, error_message) tuple
        """
        collisions = self.get_collisions(field_type)
        if not collisions:
            return True, ""

        lines = ["Uniqueness violations found:"]
        for key, sources in sorted(collisions.items()):
            lines.append(f"  {key}: {sources}")
        return False, "\n".join(lines)

    def clear(self) -> None:
        """Clear all registered values."""
        self._seen.clear()
