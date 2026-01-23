# OpenCode Subprocess Integration Architecture

## Overview

OpenCode can integrate with external subprocess agents (like Ralph) using its plugin system, tool framework, and subprocess execution capabilities. This document outlines the architecture for spawning, monitoring, and interacting with external agent processes from OpenCode's TUI.

## Core Components

### 1. Subprocess Spawning (bun-pty)

OpenCode uses `bun-pty` for spawning and communicating with subprocesses:

```typescript
import { spawn } from 'bun-pty'

interface SubprocessOptions {
  cmd: string
  args: string[]
  cwd: string
  env?: Record<string, string>
  timeout?: number
}

class SubprocessManager {
  private processes = new Map<string, PTY>()

  spawn(instanceId: string, options: SubprocessOptions): string {
    const pty = spawn({
      name: 'xterm-color',
      cols: 80,
      rows: 24,
      cwd: options.cwd,
      env: { ...process.env, ...options.env }
    })

    pty.write(`${options.cmd} ${options.args.join(' ')}\n`)
    pty.on('data', (data) => {
      // Process output
      this.handleOutput(instanceId, data)
    })

    pty.on('exit', ({ exitCode, signalName }) => {
      // Handle process termination
      this.handleExit(instanceId, exitCode, signalName)
    })

    this.processes.set(instanceId, pty)
    return instanceId
  }

  terminate(instanceId: string): void {
    const pty = this.processes.get(instanceId)
    if (pty) {
      pty.kill()
      this.processes.delete(instanceId)
    }
  }
}
```

### 2. Plugin Hooks for Lifecycle Management

OpenCode's plugin system provides hooks for managing subprocess lifecycle:

```typescript
import type { Plugin, Hooks } from '@opencode-ai/plugin'

const RalphPlugin: Plugin = async (input) => {
  const { client, project, directory, serverUrl, $ } = input

  const hooks: Hooks = {
    // Hook called when chat message is sent
    'chat.message': async ({ sessionID, agent }, output) => {
      // Intercept and route to subprocess if needed
      if (agent === 'ralph') {
        const instanceId = getSessionAgent(sessionID)
        await subprocessManager.sendMessage(instanceId, output.message.content)
      }
    },

    // Hook called when tool is about to execute
    'tool.execute.before': async ({ sessionID, tool, callID }, output) => {
      if (tool.startsWith('ralph_')) {
        // Prepare subprocess execution
        output.args.instanceId = getSessionAgent(sessionID)
      }
    },

    // Hook called after tool execution
    'tool.execute.after': async ({ sessionID, tool, callID }, output) => {
      if (tool.startsWith('ralph_')) {
        // Process subprocess response
        await processSubprocessOutput(output.output)
      }
    }
  }

  return hooks
}
```

### 3. Tool Definitions

Define OpenCode tools that spawn and interact with subprocesses:

```typescript
import { Tool } from '@opencode-ai/plugin/tool'

export const ralphSpawnTool = Tool.define({
  name: 'ralph_spawn',
  description: 'Spawn an external Ralph agent subprocess',
  parameters: {
    agent: {
      type: 'string',
      description: 'Agent name (e.g., MARGE, LISA)',
      enum: ['MARGE', 'LISA', 'RALPH', 'HAIKU']
    },
    prompt: {
      type: 'string',
      description: 'Instructions/prompt for agent'
    }
  },
  execute: async ({ agent, prompt }, context) => {
    const instanceId = `${agent.toLowerCase()}-${crypto.randomUUID().slice(0, 8)}`

    // Spawn subprocess
    subprocessManager.spawn(instanceId, {
      cmd: 'bundle',
      args: ['exec', 'ruby', '-e', `Ralph::Agent.new('${agent}').call('${prompt}')`],
      cwd: context.directory,
      env: {
        RALPH_LOG_FILE: `events/${instanceId}.jsonl`,
        INSTANCE_ID: instanceId
      }
    })

    // Store session-agent mapping
    await storeSessionAgent(context.sessionID, instanceId)

    return {
      success: true,
      instanceId,
      message: `Spawned ${agent} agent (instance: ${instanceId})`
    }
  }
})

export const ralphMessageTool = Tool.define({
  name: 'ralph_message',
  description: 'Send a message to a running Ralph agent',
  parameters: {
    instanceId: {
      type: 'string',
      description: 'Agent instance ID'
    },
    message: {
      type: 'string',
      description: 'Message to send'
    }
  },
  execute: async ({ instanceId, message }, context) => {
    // Write to subprocess stdin
    const pty = subprocessManager.getProcess(instanceId)
    if (!pty) {
      throw new Error(`Process ${instanceId} not found`)
    }

    pty.write(`${message}\n`)

    return {
      success: true,
      instanceId
    }
  }
})

export const ralphStatusTool = Tool.define({
  name: 'ralph_status',
  description: 'Get status of a Ralph agent subprocess',
  parameters: {
    instanceId: {
      type: 'string',
      description: 'Agent instance ID'
    }
  },
  execute: async ({ instanceId }) => {
    const pty = subprocessManager.getProcess(instanceId)

    if (!pty) {
      return {
        status: 'not_found',
        instanceId
      }
    }

    return {
      status: 'running',
      instanceId,
      pid: pty.pid
    }
  }
})
```

### 4. Event Stream Consumption

OpenCode can consume JSONL event files from subprocesses:

```typescript
import { watch } from 'fs/promises'

class EventStreamConsumer {
  private watchers = new Map<string, FSWatcher>()

  async watch(instanceId: string, eventFile: string): Promise<void> {
    const watcher = watch(eventFile)
    let lastPosition = 0

    this.watchers.set(instanceId, watcher)

    for await (const event of watcher) {
      if (event.eventType === 'change') {
        await this.readNewEvents(eventFile, lastPosition)
      }
    }
  }

  private async readNewEvents(filePath: string, fromPosition: number): Promise<void> {
    const file = Bun.file(filePath)
    const content = await file.text()

    // Read only new content
    const newContent = content.slice(fromPosition)
    const events = newContent.split('\n')
      .filter(Boolean)
      .map(JSON.parse)

    // Emit events to OpenCode event bus
    for (const event of events) {
      await this.emitToBus(event)
    }
  }

  stopWatching(instanceId: string): void {
    const watcher = this.watchers.get(instanceId)
    if (watcher) {
      watcher.close()
      this.watchers.delete(instanceId)
    }
  }
}
```

### 5. Message Mapping to OpenCode

Map subprocess events to OpenCode message parts for TUI display:

```typescript
import type { MessagePart } from '@opencode-ai/sdk'

function mapRalphEventToMessagePart(event: RalphEvent): MessagePart {
  switch (event.event) {
    case 'reasoning_start':
      return {
        type: 'reasoning',
        id: generateId(),
        text: '',
        time: { start: event.timestamp }
      }

    case 'reasoning_end':
      return {
        type: 'reasoning',
        id: event.data.partId,
        text: event.data.content,
        time: { start: event.data.startTime, end: event.timestamp }
      }

    case 'tool_call':
      return {
        type: 'tool_call',
        id: event.data.callId,
        tool: event.data.toolName,
        args: event.data.args,
        time: { start: event.timestamp }
      }

    case 'tool_response':
      return {
        type: 'tool_response',
        id: event.data.callId,
        output: event.data.output,
        time: { end: event.timestamp }
      }

    case 'agent_complete':
      return {
        type: 'text',
        id: generateId(),
        text: `SUCCESS: ${event.data.summary}`,
        time: { start: event.data.startTime, end: event.timestamp }
      }

    default:
      return null
  }
}
```

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenCode TUI                            │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐            │
│  │  Session  │  │  Session  │  │  Session  │            │
│  │   MARGE   │  │  RALPH    │  │   LISA    │            │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘            │
└────────┼──────────────┼──────────────┼───────────────────┘
         │              │              │
         ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│                 OpenCode Plugin Layer                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  - Tool definitions (spawn, message, status)       │  │
│  │  - Plugin hooks (chat.message, tool.execute.*)      │  │
│  │  - Event bus integration                           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│            Subprocess Manager (bun-pty)                     │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐            │
│  │ PTY #1    │  │ PTY #2    │  │ PTY #3    │            │
│  │Ruby Proc  │  │Ruby Proc  │  │Ruby Proc  │            │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘            │
└────────┼──────────────┼──────────────┼───────────────────┘
         │              │              │
         ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│               External Processes (Ralph)                    │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐            │
│  │ MARGE #1  │  │ RALPH #1  │  │ LISA #1   │            │
│  │events.jsonl│  │events.jsonl│  │events.jsonl│            │
│  └───────────┘  └───────────┘  └───────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Session Management Strategy

Each OpenCode session maps to one external subprocess:

```typescript
class SessionAgentMap {
  private sessions = new Map<string, string>()  // sessionID -> instanceId

  async associate(sessionID: string, instanceId: string): Promise<void> {
    await Storage.set(`session:${sessionID}:agent`, instanceId)
    this.sessions.set(sessionID, instanceId)
  }

  async getAgent(sessionID: string): Promise<string | null> {
    if (this.sessions.has(sessionID)) {
      return this.sessions.get(sessionID)!
    }

    const instanceId = await Storage.get(`session:${sessionID}:agent`)
    if (instanceId) {
      this.sessions.set(sessionID, instanceId)
      return instanceId
    }

    return null
  }

  async dissociate(sessionID: string): Promise<void> {
    await Storage.delete(`session:${sessionID}:agent`)
    this.sessions.delete(sessionID)
  }
}
```

## Implementation Steps

1. **Create OpenCode Plugin Package**
   - Initialize plugin with proper package.json
   - Expose plugin entry point with hooks

2. **Implement Subprocess Manager**
   - Use bun-pty for process spawning
   - Track process lifecycle
   - Handle process termination

3. **Define Tools**
   - `ralph_spawn` - Spawn agent subprocess
   - `ralph_message` - Send messages to subprocess
   - `ralph_status` - Query subprocess status
   - `ralph_stop` - Terminate subprocess

4. **Implement Event Stream Consumer**
   - Watch JSONL files for changes
   - Parse and emit events
   - Map events to OpenCode message parts

5. **Integrate with Session Management**
   - Map sessions to subprocess instances
   - Handle session cleanup on close
   - Persist mappings for recovery

6. **Add Plugin Hooks**
   - Route messages to subprocesses
   - Transform subprocess output to OpenCode format
   - Handle subprocess lifecycle events

7. **Error Handling**
   - Process crashes and restarts
   - Stale event streams
   - Network timeouts
   - Resource cleanup

## Benefits

- **Isolation**: Each subprocess has its own process space
- **Flexibility**: Can integrate with any external tool
- **Real-time**: Subprocess output streams directly to TUI
- **Stateless**: OpenCode doesn't manage subprocess state
- **Extensible**: Easy to add new subprocess types
