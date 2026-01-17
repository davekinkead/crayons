We have agents, clients, and tools.

Agents encapsulate domain logic and perform a tast until complete.

Each agent has it's own context/thread of operations so needs to manage this.

An orchestrator agent will create a sub agent and set them to work with `.call` with an optional message.

Agents work and return success or an error message.

The client must get an agent's system prompt, tools, and converstaion history and convert it for the API.


Agents
  - defined by markdown
  - specifies permitted tools
  - specifies behaviour

agent.rb
  - loads agents
  - have a client injected
  - manages turn logic
  - invokes tools and responds
  - returns success or failure

Clients
  - manage API specific infra

Tools
  - define what a tool can do
