# Claude Code Skills

A collection of custom skills for [Claude Code](https://claude.ai/claude-code) — the official CLI for Claude. Each skill extends Claude Code with new slash commands that can be invoked directly from the terminal.

---

## What Are Claude Code Skills?

Skills are prompt templates that Claude Code loads as slash commands. When you invoke `/skill-name`, Claude Code injects the template into the conversation with your arguments and any dynamic context (current branch, recent diffs, etc.) pre-filled.

Each skill in this repo lives in its own subdirectory and contains at minimum a `SKILL.md` file that defines the command behavior.

---

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and authenticated
- Claude Code must be configured to load skills from `~/.claude/skills/`

---

## Installation

### Install all skills

```bash
git clone https://github.com/<your-username>/claude-code-skills.git ~/.claude/skills
```

### Install a single skill

```bash
# Copy only the skill subdirectory you want
cp -r /path/to/repo/<skill-name> ~/.claude/skills/
```

After copying, the skill is immediately available as `/<skill-name>` in any Claude Code session.

---

## Skill Catalog

| Skill | Command | Description |
|---|---|---|
| [prompt-enhancer](./prompt-enhancer/) | `/prompt-enhancer [your request]` | Classifies your task, resolves ambiguities, rewrites the prompt with professional structure, presents implementation alternatives, and produces a detailed plan — all before writing a single line of code. |

---

## Contributing

To add a new skill:

1. Create a subdirectory: `skills/<skill-name>/`
2. Add a `SKILL.md` file following the existing skill format (frontmatter + prompt body)
3. Add a row to the catalog table above
4. Open a pull request against `main`
