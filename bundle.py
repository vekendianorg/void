"""
bundle.py — VOID packing tool
Embeds all src/ modules into a single VFS-based void_packed.lua.

Usage:
  python bundle.py              # normal pack
  python bundle.py -m           # pack + strip Lua comments (minify)
  python bundle.py -o out.lua   # custom output path
  python bundle.py -v 1.0.0     # inject version string
"""

import os
import re
import sys
import argparse
from datetime import datetime

SRC_DIR   = "src"
MAIN_FILE = os.path.join(SRC_DIR, "main.lua")
DEFAULT_OUTPUT = "void_packed.lua"


# ── Module collection ──────────────────────────────────────────────────────────

def collect_modules():
    """Walk src/ and return an OrderedDict-like list of (virtual_name, real_path)
    for every .lua file except main.lua."""
    modules = {}
    for root, dirs, files in os.walk(SRC_DIR):
        dirs[:] = sorted(d for d in dirs if not d.startswith("{"))
        for filename in sorted(files):
            if not filename.endswith(".lua"):
                continue
            real_path    = os.path.join(root, filename)
            virtual_name = os.path.relpath(real_path, SRC_DIR).replace(os.sep, "/")
            if virtual_name == "main.lua":
                continue
            modules[virtual_name] = real_path
    return modules


# ── main.lua loader block stripping ───────────────────────────────────────────

def strip_loader_block(lines):
    """Remove the native `local scriptDir` + `function loadModule … end` block.

    The bundler replaces both with its own VFS-aware versions, so the originals
    must be removed to avoid duplicate-definition errors at runtime.

    Returns (cleaned_lines, diagnostic_string).
    """
    start_idx = None
    end_idx   = None
    depth     = 0

    for i, line in enumerate(lines):
        s = line.strip()

        if "function loadModule" in s:
            start_idx = i
            depth = 1
            continue

        if start_idx is not None and depth > 0:
            # Increment depth for block-openers
            if (re.search(r'\bthen\b', s) or re.search(r'\bdo\b', s)
                    or re.search(r'\bfunction\b', s)):
                depth += 1
            # Decrement depth for 'end' tokens
            if re.search(r'\bend\b', s):
                depth -= 1
            if depth == 0:
                end_idx = i
                break

    if start_idx is None or end_idx is None:
        return lines, "Warning: loadModule block not found — skipping strip."

    # Backtrack to also remove the scriptDir line and any blank lines above it
    scan = start_idx - 1
    while scan >= 0:
        prev = lines[scan].strip()
        if prev == "" or "local scriptDir" in prev:
            scan -= 1
        else:
            break
    strip_from = scan + 1

    diag = f"Stripped loader block (lines {strip_from + 1}–{end_idx + 1})"
    del lines[strip_from : end_idx + 1]
    return lines, diag


# ── Lua minifier (basic) ───────────────────────────────────────────────────────

def _lua_strip_comment(line):
    """Strip a trailing single-line `-- ...` comment from *line*, respecting
    quoted strings.  Long comments `--[[...]]` on a line by themselves are
    removed entirely.  Returns the cleaned line (with its original newline)."""
    # Drop standalone long-comment lines
    if re.match(r'^\s*--\[\[', line):
        return "\n"

    result  = []
    i       = 0
    src     = line.rstrip("\n")
    n       = len(src)
    in_str  = None   # None | '"' | "'"

    while i < n:
        ch = src[i]

        if in_str:
            result.append(ch)
            if ch == "\\" and i + 1 < n:          # escape sequence
                i += 1
                result.append(src[i])
            elif ch == in_str:
                in_str = None
        else:
            if ch in ('"', "'"):
                in_str = ch
                result.append(ch)
            elif src[i:i+2] == "--":               # comment starts here
                break
            else:
                result.append(ch)
        i += 1

    return "".join(result).rstrip() + "\n"


def minify_lua(source):
    """Strip single-line comments and collapse consecutive blank lines."""
    cleaned    = []
    prev_blank = False

    for line in source.splitlines(keepends=True):
        stripped = _lua_strip_comment(line)
        is_blank = stripped.strip() == ""

        if is_blank:
            if not prev_blank:
                cleaned.append("\n")
            prev_blank = True
        else:
            cleaned.append(stripped)
            prev_blank = False

    return "".join(cleaned)


# ── VFS loader (replaces the stripped native loader) ──────────────────────────

def build_vfs_loader():
    return """\
local scriptDir = gg.getFile():match("(.*/)" ) or ""
script_dir = scriptDir  -- bridge for lang.lua and other modules

function loadModule(name, soft)
    local key = name:gsub("^%./", "")
    if not key:match("%.lua$") then key = key .. ".lua" end
    local vchunk = __vfs[key]
    if vchunk then
        -- Soft mode: run the module body guarded so a feature crash returns
        -- nil, err instead of propagating (mirrors main.lua's loadModule).
        if soft then
            local results = table.pack(pcall(vchunk))
            if not results[1] then return nil, results[2] end
            return table.unpack(results, 2, results.n)
        end
        return vchunk()
    end
    local path = scriptDir .. name
    local chunk, err = loadfile(path)
    if not chunk then
        if soft then return nil, err end
        gg.alert("VFS miss: " .. name .. "\\n" .. tostring(err))
        os.exit()
    end
    if soft then
        local results = table.pack(pcall(chunk))
        if not results[1] then return nil, results[2] end
        return table.unpack(results, 2, results.n)
    end
    return chunk()
end
"""


# ── Main bundler ───────────────────────────────────────────────────────────────

def bundle(output_file, do_minify, version=None):
    if not os.path.exists(MAIN_FILE):
        print(f"[-] Entry point not found: {MAIN_FILE}")
        print("    Run this script from the project root (folder containing 'src/').")
        sys.exit(1)

    modules = collect_modules()
    parts   = [
        f"-- Packed by bundle.py  •  {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n",
        "-- Do not edit — regenerate with:  python bundle.py\n\n",
        "local __vfs = {}\n",
    ]

    total_src_bytes = 0

    for virtual_name, real_path in modules.items():
        if not os.path.exists(real_path):
            print(f"[-] Skipped (missing): {real_path}")
            continue
        with open(real_path, encoding="utf-8") as f:
            content = f.read()
        total_src_bytes += len(content.encode("utf-8"))
        if do_minify:
            content = minify_lua(content)
        sz = len(content.encode("utf-8"))
        print(f"[+] {virtual_name:<45}  {sz:>7,} B")
        parts.append(f"__vfs['{virtual_name}'] = function(...)\n{content}\nend\n")

    # Process main.lua
    with open(MAIN_FILE, encoding="utf-8") as f:
        lines = f.readlines()

    lines, diag = strip_loader_block(lines)
    print(f"[~] {diag}")

    main_src = "".join(lines)

    # ── Version Injection ─────────────────────────────────────────────────────
    if version:
        main_src = re.sub(
            r'scriptSubHeader\s*=\s*"[^"]*"',
            f'scriptSubHeader = " v{version} • By Vekendian"',
            main_src
        )
        print(f"[~] Version injected: v{version}")

    total_src_bytes += len(main_src.encode("utf-8"))
    if do_minify:
        main_src = minify_lua(main_src)

    parts.append(build_vfs_loader())
    parts.append("\n-- ── MAIN ENTRYPOINT ──────────────────────────────────────────────────────\n\n")
    parts.append(main_src)

    output = "\n".join(parts)
    out_bytes = output.encode("utf-8")

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(output)

    # ── Stats ─────────────────────────────────────────────────────────────────
    line_count = output.count("\n")
    ratio      = (1 - len(out_bytes) / total_src_bytes) * 100 if total_src_bytes else 0
    tag        = "  [minified]" if do_minify else ""

    print()
    print(f"[✔] Output  →  '{output_file}'{tag}")
    print(f"    Modules :  {len(modules)}")
    print(f"    Lines   :  {line_count:,}")
    print(f"    Size    :  {len(out_bytes):,} B  ({len(out_bytes)/1024:.1f} KB)")
    if do_minify:
        print(f"    Savings :  {ratio:.1f}% vs unminified sources")


# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Pack VOID src/ modules into a single Lua file.")
    parser.add_argument(
        "-m", "--minify",
        action="store_true",
        help="Strip single-line Lua comments and collapse blank lines")
    parser.add_argument(
        "-o", "--output",
        default=DEFAULT_OUTPUT,
        metavar="FILE",
        help=f"Output file path (default: {DEFAULT_OUTPUT})")
    parser.add_argument(
        "-v", "--version",
        default=None,
        metavar="VERSION",
        help="Inject version string into scriptSubHeader")
        
    args = parser.parse_args()

    bundle(output_file=args.output, do_minify=args.minify, version=args.version)
