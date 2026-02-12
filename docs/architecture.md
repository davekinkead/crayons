# Crayons Architecture

Crayons is built on a client-server-resource model:

## Client Layer
User interfaces that interact with the server
- `/clients/web` - Web client (browser-based UI)
- `/clients/tui` - Terminal User Interface (CLI/TUI)

## Server Layer
HTTP/WebSocket wrapper around core library
- `/server` - HTTP server with WebSocket support
  - RESTful API endpoints for tool invocation
  - WebSocket connections for real-time communication
  - Authentication and authorization
  - Request routing and dispatch

## Core Library
Business logic and tool execution
- `/lib` for code (everything in Crayons namespace)
  - `tool.rb` → Crayons::Tool (base class)
  - `errors.rb` → Crayons::ToolNotFoundError (exceptions)
  - `tools.rb` → Crayons::Tools (factory module)
  - `tools/`
    - `haiku.rb` → Crayons::Tools::Haiku (individual tool)

## Services Layer
External services and integrations
- `/lib/crayons/services` - External resource adapters
  - `base.rb` → Crayons::Services::Base
  - `zai.rb` → Crayons::Services::Zai
  - `http.rb` → Crayons::Services::HTTP
  - `openai.rb` → Crayons::Services::OpenAI
  - `claude.rb` → Crayons::Services::Claude

## Data Flow

1. **Client** sends request to Server (HTTP/WebSocket)
2. **Server** authenticates and routes request to Core
3. **Core** executes tool logic, using Services as needed
4. **Services** communicate with external services
5. **Core** returns results to Server
6. **Server** streams response back to Client

## Directory Structure

```
crayons-rb/
├── clients/
│   ├── web/           # Web UI (browser-based)
│   └── tui/           # Terminal UI
├── server/            # HTTP/WebSocket server
├── lib/               # Core library
│   ├── crayons/
│   │   ├── agent.rb
│   │   ├── message.rb
│   │   ├── tool.rb
│   │   ├── errors.rb
│   │   ├── tools.rb
│   │   ├── tools/
│   │   └── services/
│   │       ├── base.rb
│   │       ├── http.rb
│   │       ├── zai.rb
│   │       ├── openai.rb
│   │       └── claude.rb
└── spec/              # Tests
```
