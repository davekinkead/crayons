# Crayons

![I'm in everything now](ralphy.jpg)

Crayons is an **experimental** ralph-loop for autonomous software development via simple agents defined as markdown files.

## Principle

* Expect failure. LLMs are non-deterministic - design around the inevitability of failure.
* Agents are tools. A unified interface means agents can use other agent like they use deterministic tools.
* Keep 'em stupid. Agents should do one thing and do it well.
* Context is king. Keep it lean and don't leak it.
* Performance through parallelisation. Design for concurrency.
* Correctness over completeness. Implementation is incremental but always production ready.

Inspired by [Geoffrey Huntley](https://ghuntley.com/ralph/).

## Features

- Define agents via markdown.
- A common DSL for agents and tool
- Concurrent tool execution via batch tooling for performance
- Deterministic context management
- Test-first development with RSpec

## Documentation

- [AGENTS.md](AGENTS.md) - Quick start guide for agents
- [docs/architecture.md](docs/architecture.md) - System architecture and components
- [docs/testing.md](docs/testing.md) - Testing guidelines and structure

## License

Copyright Dave Kinkead 2026
