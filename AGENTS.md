# Crayons

Crayons is an experiment in autonymous agentic coding based on the Ralph Wiggum technique.

## Important Documents

- [README.md](README.md) - Quick start guide for humans
- [docs/architecture.md](docs/architecture.md) - System architecture and components
- [docs/code-quality.md](docs/code-quality.md) - Implementation guidelines
- [docs/testing.md](docs/testing.md) - Testing guidelines and structure


## Custom Agents

There are a range of custom agents defined in `agents/*.md`.

To run one of these agents, use `bin/agent --agent NAME --call "prompt message"`.

If told to use a custom or crayon agent, or a upcased name like "Use MARGE to ...", this is what you should do.

## Important

- If you are writing code, ALWAYS follow TDD red before green.
- ALWAYS verify your work with `bin/verify`.
- NEVER delete a file without asking the user.
