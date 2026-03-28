#!/usr/bin/env python3
"""
generate_specialist.py - Generate Claude agent templates from documentation libraries.

Usage:
    python3 generate_specialist.py /path/to/biblioteca/folder [options]

Reads INDEX.md, index.json, and FULL_DOCS.md to auto-generate a specialized
Claude agent JSON file with full library references.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

TEMPLATE_PATH = Path(__file__).parent.parent / "templates" / "specialist_base.md"
DEFAULT_OUTPUT_DIR = Path.home() / ".claude" / "agent-templates"
DEFAULT_TOOLS = ["Read", "Grep", "Glob", "WebSearch", "WebFetch", "Bash"]


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate Claude agent templates from documentation libraries"
    )
    parser.add_argument(
        "library_path",
        help="Path to the documentation library folder",
    )
    parser.add_argument(
        "-o", "--output",
        help="Output JSON file path (default: ~/.claude/agent-templates/{name}.json)",
    )
    parser.add_argument(
        "--name",
        help="Agent name (default: auto-detected from folder name)",
    )
    parser.add_argument(
        "--lang",
        choices=["es", "en"],
        default="es",
        help="Language for the agent instructions (default: es)",
    )
    parser.add_argument(
        "--tools",
        help=f"Comma-separated list of tools (default: {','.join(DEFAULT_TOOLS)})",
    )
    return parser.parse_args()


def read_file(path, encoding="utf-8"):
    """Read a file and return its content, or None if not found."""
    try:
        with open(path, "r", encoding=encoding) as f:
            return f.read()
    except FileNotFoundError:
        return None
    except UnicodeDecodeError:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()


def detect_product_name(folder_name):
    """Convert folder name to a readable product name."""
    # elevenlabs-agents-platform -> ElevenLabs Agents Platform
    parts = folder_name.replace("_", "-").split("-")
    return " ".join(p.capitalize() for p in parts)


def parse_index_md(content):
    """Extract categories and page entries from INDEX.md."""
    categories = {}
    current_category = None

    for line in content.split("\n"):
        line = line.strip()
        # Category headers (## Level)
        if line.startswith("## ") and not line.startswith("###"):
            current_category = line[3:].strip()
            categories[current_category] = []
        # Page entries (- [title](file))
        elif line.startswith("- [") and current_category:
            match = re.match(r"- \[(.+?)\]\((.+?)\)", line)
            if match:
                title = match.group(1)
                filename = match.group(2)
                categories[current_category].append({
                    "title": title,
                    "filename": filename,
                })

    return categories


def parse_index_json(content):
    """Extract metadata from index.json."""
    try:
        data = json.loads(content)
        return {
            "base_url": data.get("base_url", ""),
            "framework": data.get("framework", "unknown"),
            "page_count": len(data.get("pages", [])),
            "pages": data.get("pages", []),
        }
    except (json.JSONDecodeError, TypeError):
        return {"base_url": "", "framework": "unknown", "page_count": 0, "pages": []}


def extract_key_concepts(full_docs_content, max_concepts=30):
    """Extract top headings from FULL_DOCS.md as key concepts."""
    concepts = []
    seen = set()

    for line in full_docs_content.split("\n"):
        line = line.strip()
        # Match ## and ### headings (skip # which is the doc title)
        if re.match(r"^#{2,3}\s+", line):
            heading = re.sub(r"^#{2,3}\s+", "", line).strip()
            # Skip generic headings
            skip_patterns = [
                "tabla de contenidos", "table of contents",
                "page-", "index", "---",
            ]
            if any(p in heading.lower() for p in skip_patterns):
                continue
            if heading and heading.lower() not in seen and len(heading) > 3:
                seen.add(heading.lower())
                concepts.append(heading)
                if len(concepts) >= max_concepts:
                    break

    return concepts


def get_folder_size_kb(folder_path):
    """Get total size of .md files in folder in KB."""
    total = 0
    for f in Path(folder_path).glob("*.md"):
        total += f.stat().st_size
    return round(total / 1024)


def get_scrape_date(index_md_content):
    """Extract scrape date from INDEX.md header."""
    match = re.search(r"(\d{4}-\d{2}-\d{2})", index_md_content or "")
    if match:
        return match.group(1)
    return datetime.now().strftime("%Y-%m-%d")


def format_categories(categories, lang="es"):
    """Format categories for the agent instructions."""
    lines = []
    for cat, pages in categories.items():
        lines.append(f"### {cat}")
        for page in pages:
            lines.append(f"- {page['title']} → `{page['filename']}`")
        lines.append("")
    return "\n".join(lines)


def format_key_concepts(concepts):
    """Format key concepts as a bullet list."""
    return "\n".join(f"- {c}" for c in concepts)


def build_instructions(template, name, product, library_path, page_count,
                       size_kb, date, categories_text, concepts_text, lang):
    """Build the full instructions by filling the template."""
    instructions = template.replace("{name}", name)
    instructions = instructions.replace("{product}", product)
    instructions = instructions.replace("{library_path}", library_path)
    instructions = instructions.replace("{page_count}", str(page_count))
    instructions = instructions.replace("{size_kb}", str(size_kb))
    instructions = instructions.replace("{date}", date)
    instructions = instructions.replace("{categories}", categories_text)
    instructions = instructions.replace("{key_concepts}", concepts_text)

    if lang == "es":
        lang_note = (
            "\n\n## Idioma\n\n"
            "Responde SIEMPRE en español. Los términos técnicos y código "
            "pueden mantenerse en inglés."
        )
    else:
        lang_note = ""

    instructions += lang_note
    return instructions


def build_description(product, page_count, lang):
    """Generate agent description."""
    if lang == "es":
        return (
            f"Especialista experto en {product} con acceso a {page_count} "
            f"páginas de documentación oficial. Consulta la biblioteca local "
            f"para dar respuestas precisas basadas en docs actualizados."
        )
    return (
        f"Expert specialist in {product} with access to {page_count} "
        f"pages of official documentation. Queries local library for "
        f"precise answers based on up-to-date docs."
    )


def main():
    args = parse_args()

    library_path = os.path.abspath(args.library_path)
    if not os.path.isdir(library_path):
        print(f"Error: '{library_path}' is not a valid directory", file=sys.stderr)
        sys.exit(1)

    folder_name = os.path.basename(library_path)

    # Auto-detect name
    agent_name = args.name or f"{detect_product_name(folder_name)} Specialist"

    # Read library files
    index_md = read_file(os.path.join(library_path, "INDEX.md"))
    index_json = read_file(os.path.join(library_path, "index.json"))
    full_docs = read_file(os.path.join(library_path, "FULL_DOCS.md"))

    if not index_md:
        print("Warning: INDEX.md not found, categories will be empty", file=sys.stderr)
    if not full_docs:
        print("Warning: FULL_DOCS.md not found, concepts will be empty", file=sys.stderr)

    # Parse data
    categories = parse_index_md(index_md or "")
    metadata = parse_index_json(index_json or "{}")
    concepts = extract_key_concepts(full_docs or "")
    size_kb = get_folder_size_kb(library_path)
    date = get_scrape_date(index_md)
    page_count = metadata["page_count"] or sum(len(v) for v in categories.values())
    product = detect_product_name(folder_name)

    # Read template
    template = read_file(str(TEMPLATE_PATH))
    if not template:
        print(f"Error: Template not found at {TEMPLATE_PATH}", file=sys.stderr)
        sys.exit(1)

    # Build instructions
    categories_text = format_categories(categories, args.lang)
    concepts_text = format_key_concepts(concepts)

    instructions = build_instructions(
        template=template,
        name=agent_name,
        product=product,
        library_path=library_path,
        page_count=page_count,
        size_kb=size_kb,
        date=date,
        categories_text=categories_text,
        concepts_text=concepts_text,
        lang=args.lang,
    )

    # Tools
    tools = args.tools.split(",") if args.tools else DEFAULT_TOOLS

    # Build agent JSON
    agent = {
        "name": agent_name,
        "description": build_description(product, page_count, args.lang),
        "instructions": instructions,
        "tools": tools,
    }

    # Output path
    if args.output:
        output_path = os.path.abspath(args.output)
    else:
        DEFAULT_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        safe_name = re.sub(r"[^a-zA-Z0-9_-]", "-", agent_name.lower().replace(" ", "-"))
        output_path = str(DEFAULT_OUTPUT_DIR / f"{safe_name}.json")

    # Write
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(agent, f, indent=2, ensure_ascii=False)

    print(f"Agent generated: {output_path}")
    print(f"  Name: {agent_name}")
    print(f"  Pages: {page_count}")
    print(f"  Size: {size_kb} KB")
    print(f"  Categories: {len(categories)}")
    print(f"  Key concepts: {len(concepts)}")
    print(f"  Tools: {', '.join(tools)}")
    print(f"  Language: {args.lang}")


if __name__ == "__main__":
    main()
