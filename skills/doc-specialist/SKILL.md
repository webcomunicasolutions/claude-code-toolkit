---
name: doc-specialist
description: Generate specialized Claude agents from scraped documentation libraries. Automates the flow from docs → agent template with full library references.
triggers:
  - "generar agente"
  - "doc specialist"
  - "crear especialista"
  - "generate agent from docs"
  - "crear agente desde docs"
  - "especialista desde documentación"
  - "specialist from library"
---

# Doc Specialist - Agent Generator from Documentation Libraries

Generate specialized Claude agent templates from any scraped documentation library in `biblioteca/`.

## Decision Tree

1. **User wants to generate an agent from docs** → Run `generate_specialist.py`
2. **User wants to consult library docs directly** → Read files from `biblioteca/` folder
3. **User just finished scraping** → Suggest generating an agent

## Usage

### Generate a specialist agent from a library folder

```bash
python3 ~/.claude/skills/doc-specialist/scripts/generate_specialist.py \
  "~/docs/biblioteca/elevenlabs-agents-platform" \
  --name "ElevenLabs Specialist" \
  --lang es
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `PATH` (positional) | Library folder path (required) | - |
| `-o, --output` | Output JSON path | `~/.claude/agent-templates/{name}.json` |
| `--name` | Agent name | Auto-detected from folder name |
| `--lang` | Language (es/en) | es |
| `--tools` | Comma-separated tools | Read,Grep,Glob,WebSearch,WebFetch,Bash |

### Output

A JSON file compatible with Claude Code agent format:
```json
{
  "name": "Agent Name",
  "description": "Auto-generated description",
  "instructions": "Full system prompt with library references",
  "tools": ["Read", "Grep", "Glob", "WebSearch", "WebFetch", "Bash"]
}
```

## Integration with web-scraper skill

1. Scrape docs: `python3 ~/.claude/skills/web-scraper/scripts/scrape_docs.py URL -o biblioteca/nombre/`
2. Generate agent: `python3 ~/.claude/skills/doc-specialist/scripts/generate_specialist.py biblioteca/nombre/`
3. Use agent in any project by copying the JSON to `.claude/agents/`

## Library Format Expected

The script expects the output format from `web-scraper` skill:
- `INDEX.md` - Categorized index of pages
- `index.json` - Metadata (URLs, titles, filenames)
- `FULL_DOCS.md` - All pages consolidated
- `*.md` - Individual page files


## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si el patron es generalizable, actualizar el cuerpo de este SKILL.md
3. Si se descubre un error recurrente, anadirlo a una seccion de "Errores conocidos"

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
