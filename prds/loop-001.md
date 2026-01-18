# Agent Spawning Tool - PRD

## Overview

RALPH needs the ability to spawn and execute other agents (CODER, REVIEWER) as part of the orchestration loop. This capability enables RALPH to delegate implementation and validation tasks while maintaining control over the overall workflow.

## Goals

- Enable RALPH to spawn CODER agent to implement PRDs
- Enable RALPH to spawn REVIEWER agent to validate specs
- Spawned agents maintain fresh, independent context from parent agent
- Spawned agent responses use standard promise format for loop control
- Any agent can spawn any other agent (future-proof flexibility)

## User Stories

- As RALPH, I want to spawn CODER with PRD requirements, so that implementation work can begin
- As RALPH, I want to spawn REVIEWER after CODER completes, so that code quality is validated
- As RALPH, I want to know when spawned agents succeed or fail, so I can control the dev-review loop
- As a spawned agent, I want to start with clean context, so that I'm not polluted by parent agent's history

## Acceptance Criteria

- [ ] Tool exists that can spawn an agent by name
- [ ] Tool accepts the agent name and instruction prompt
- [ ] Tool blocks execution until spawned agent completes
- [ ] Tool returns the spawned agent's full response
- [ ] Spawned agent uses the same promise format as direct agent calls
- [ ] Spawned agent cannot access parent agent's chat history
- [ ] Tool handles invalid agent names with clear error messages
- [ ] Tool propagates agent initialization or execution errors

## Technical Requirements

- Tool name: `spawn_agent`
- Input parameters:
  - `agent_name`: Name of agent to spawn (symbol or string)
  - `instructions`: Prompt/instructions for the spawned agent
- Returns:
  - Spawned agent's raw response (including promise tags)
- Spawned agents use existing Ralph::Agent initialization
- Tool follows Ralph::Tool DSL pattern

## Implementation Notes

- Follow existing tool patterns in `lib/ralph/tools/`
- Register tool in Ralph::Tools registry
- Use existing Ralph::Agent class for instantiation
- Parse response to identify COMPLETE/FAILURE for loop control (handled by caller)

## Edge Cases & Error Handling

- Invalid agent name returns error message indicating available agents
- Agent file not found returns specific error
- Agent initialization failure propagates error details
- Agent execution failure (max iterations) returns agent's FAILURE response
- Empty or malformed instructions still spawn agent (agent may return FAILURE)

## Testing Requirements

- Unit test spawning CODER with simple instructions
- Unit test spawning REVIEWER with mock PRD data
- Unit test with invalid agent name (error handling)
- Unit test verifying spawned agent has independent context
- Integration test: RALPH spawns CODER which returns COMPLETE
- Integration test: RALPH spawns CODER which returns FAILURE

## Dependencies

- Existing Ralph::Agent class
- Existing tool infrastructure (RubyLLM::Tool DSL)
- No external dependencies

## Success Criteria

- RALPH can spawn CODER and REVIEWER agents
- Spawned agents execute and return responses
- Spawned agents have fresh, independent context
- Tool integrates cleanly with existing tool registry
