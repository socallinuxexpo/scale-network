#!/usr/bin/python3
import sys
import argparse
import networkx as nx
from collections import deque, defaultdict
import os

# This script generates a blockdiag .diag file from a data file containing network "hearing" events.
# Each line in the input file is expected to be in the format "A C B", meaning system A hears system B on interface C.
# The script ignores the interface (C) for graph construction and edge labels to avoid clutter.
# It builds an undirected graph using NetworkX.
# - Node names are treated case-insensitively (e.g., "confidf" and "ConfIDF" are merged).
# - Node display names are normalized: find longest common prefix among all nodes, capitalize its first letter (rest lower),
#   then append the suffix in all uppercase (non-letters unchanged).
#   Example: nodes "ballrooma", "ballrooma-1", "ballroomb", "ballroomb-1" -> common prefix "ballroom" ->
#   display: "BallroomA", "BallroomA-1", "BallroomB", "BallroomB-1".
# - External nodes: Connected only to the starting node with degree 1 (shaped as clouds).
# - Starting node: Specified by user (shaped as ellipse).
# - Internal nodes directly connected to starting: Shaped as ellipses.
# - Internal leaf nodes: Nodes that are "heard" but do not "hear" anything else (i.e., not reporters; shaped as circles).
# - Other internal nodes: Shaped as boxes.
# The script uses BFS from the starting node to assign levels and build a spanning tree for hierarchical layout.
# To prevent the diagram from becoming too wide, it creates nested groups with orientations based on presence of leaves:
#   - If a group has leaf nodes, use portrait (vertical) layout.
#   - If a group has no leaf nodes, use landscape (horizontal) layout.
# Leaf children are listed directly in the group with the parent, without a sub-group.
# Orientation statements are only included for the top two levels of groups; deeper groups have no orientation specified.
# Externals are grouped with portrait orientation to stack vertically if many, reducing width.
# The overall diagram is portrait-oriented, with externals above starting, and internal branches below, potentially stacked.
# Output: network.diag (run `blockdiag network.diag -T svg -o network.svg` or similar to generate image).
# If data_file is "-", input is read from stdin instead of a file.

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Generate a blockdiag .diag file from network hearing data.')
parser.add_argument('starting_node', help='The name of the starting node.')
parser.add_argument('data_file', help='Path to the data file, or "-" to read from stdin.')
args = parser.parse_args()

starting = args.starting_node.lower()  # Normalize to lower
filename = args.data_file

# Prepare input iterator (file or stdin)
if filename == '-':
    input_iter = sys.stdin
else:
    input_iter = open(filename, 'r')

# Initialize graph and data structures
G = nx.Graph()  # Undirected graph for connections
reporters = set()  # Set of nodes that report hearing others (A in "A C B")
edges = []  # List of (A, B) pairs for later processing

# Read and process input lines, normalizing to lowercase
for line in input_iter:
    parts = line.strip().split()
    if len(parts) == 3:
        A, C, B = parts
        a_lower = A.lower()
        b_lower = B.lower()
        G.add_edge(a_lower, b_lower)  # Add undirected edge (ignores C)
        reporters.add(a_lower)  # A is a reporter
        edges.append((a_lower, b_lower))  # Store directed pair if needed later

# Close file if not stdin
if filename != '-':
    input_iter.close()

# Compute display names: find common prefix and normalize
all_nodes = list(G.nodes)
if all_nodes:
    common_prefix = os.path.commonprefix(all_nodes)
    display_map = {}
    for node in all_nodes:
        prefix_cap = common_prefix.capitalize()
        suffix_upper = node[len(common_prefix):].upper()
        display_map[node] = prefix_cap + suffix_upper
else:
    display_map = {}

# Identify external nodes: neighbors of starting with degree 1 (only connected to starting)
externals = [nb for nb in G.neighbors(starting) if G.degree(nb) == 1]

# Internal starting points: other neighbors of starting (not externals)
internal_starts = [nb for nb in G.neighbors(starting) if nb not in externals]

# All internal nodes: all nodes except starting and externals
internals = list(set(G.nodes) - set(externals) - {starting})

# Build spanning tree, levels, and tree children using BFS (excluding externals)
tree_children = defaultdict(list)
levels = {starting: 0}
queue = deque(internal_starts)
visited = set([starting])
for n in internal_starts:
    levels[n] = 1
    visited.add(n)
    queue.append(n)
    tree_children[starting].append(n)  # Starting's children are internal_starts

while queue:
    u = queue.popleft()
    for v in G.neighbors(u):
        if v not in visited and v not in externals:
            visited.add(v)
            levels[v] = levels[u] + 1
            queue.append(v)
            tree_children[u].append(v)

# Function to write nested subtree groups with orientations based on presence of leaves
def write_subtree(out, node, level, tree_children):
    children = tree_children[node]
    leaf_children = [c for c in children if len(tree_children[c]) == 0]
    non_leaf_children = [c for c in children if len(tree_children[c]) > 0]
    has_leaves = len(leaf_children) > 0
    ori = 'portrait' if has_leaves else 'landscape'
    group_name = f'group_{node.replace("-", "_").replace(".", "_")}'  # Sanitize node name for group
    out.write(f'    group {group_name} {{\n')
    if level <= 1:
        out.write(f'      orientation = {ori};\n')
    out.write(f'      "{display_map[node]}";\n')
    for child in sorted(leaf_children):
        out.write(f'      "{display_map[child]}";\n')
    for child in sorted(non_leaf_children):
        write_subtree(out, child, level + 1, tree_children)
    out.write('    }\n')

# Write .diag file
with open('network.diag', 'w') as out:
    out.write('blockdiag {\n')
    out.write('  orientation = portrait;\n')

    # Define all nodes with shapes first (to avoid duplication issues), using quoted display names
    out.write('  // Node definitions\n')
    for node in sorted(G.nodes):
        disp = display_map.get(node, node)  # Fallback to node if no map
        if node in externals:
            shape = "cloud"
        elif node == starting or node in internal_starts:
            shape = "ellipse"
        elif node not in reporters:
            shape = "circle"
        else:
            shape = "box"
        out.write(f'  "{disp}" [shape = {shape}];\n')

    # External group (vertical stack to reduce width)
    if externals:
        out.write('  group externals {\n')
        out.write('    orientation = portrait;\n')
        out.write('    label = "Externals";\n')
        out.write('    color = "#FFFFCC";\n')
        for e in sorted(externals):
            out.write(f'    "{display_map[e]}";\n')
        out.write('  }\n')

    # Internal group (vertical overall, containing alternating subtrees)
    if internals:
        out.write('  group internals {\n')
        out.write('    orientation = portrait;\n')
        out.write('    label = "Internals";\n')
        out.write('    color = "#CCFFCC";\n')
        for i in sorted(internal_starts):
            write_subtree(out, i, 1, tree_children)
        out.write('  }\n')

    # Edges: externals -> starting (directed inward), using display names
    starting_disp = display_map.get(starting, starting)
    for e in sorted(externals):
        e_disp = display_map.get(e, e)
        out.write(f'  "{e_disp}" -> "{starting_disp}";\n')

    # All other edges, directed based on levels (lower level -> higher level for downward flow)
    # Include all edges (tree and non-tree), deduplicated
    all_edges = [(u, v) for u, v in G.edges]
    seen = set()
    # Mark external-to-starting edges as already written so they are not duplicated here
    for e in externals:
        seen.add(frozenset([e, starting]))
    for u, v in all_edges:
        edge = frozenset([u, v])
        if edge in seen:
            continue
        seen.add(edge)
        u_disp = display_map.get(u, u)
        v_disp = display_map.get(v, v)
        lu = levels.get(u, -1)
        lv = levels.get(v, -1)
        if lu < lv:
            out.write(f'  "{u_disp}" -> "{v_disp}";\n')
        elif lv < lu:
            out.write(f'  "{v_disp}" -> "{u_disp}";\n')
        else:
            # Same level or unassigned (e.g., externals or cross): arbitrary direction (alphabetical on display)
            src, dst = (u_disp, v_disp) if u_disp < v_disp else (v_disp, u_disp)
            out.write(f'  "{src}" -> "{dst}";\n')

    out.write('}\n')

print("Generated network.diag. Run 'blockdiag network.diag -T svg -o network.svg' or similar for PDF/SVG.")
