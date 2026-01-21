## Concurrency

Performance will be enhanced through the use of `async` Ruby so that calls to LLMs and agent completions do not block the process. HTTP clients will leverage Ruby's async capabilities with fiber-based concurrency, maintaining a synchronous interface for callers while enabling non-blocking I/O operations under the hood to improve throughput when multiple agents run concurrently.

HTTP clients must handle errors gracefully by rescuing from StandardError and raising appropriate NetworkError exceptions with meaningful context, avoiding direct exposure of library-specific error objects.

Concurrent agents should be possible throught the use of git worktrees. This means that agents need to be instantiated with a required 'workdir' param, this value is injected into ALL took execution. For security purposes, tool calls with argument paths not containing the workdir MUST be rejected with an appropriate message.

CLANCY will need to create git worktrees for BART. The worktree names should reflect the RPD name and the `workdir` agent param.

## Git

Concurrent agents require a specific git workflow involving git worktrees.

CLANCY works from `main` and should be created with `dir: "./"`.  CLANCY creates git worktrees that match the PRD file name. He can then spawn BART with the worktree as the dir param.

BART should be working in the context of a worktree. The allows BART to commit frequently as a way of persisting memory between agent processes (agents are ephemeral and have no memory). All tooling must therefore enforce `dir` compliance.

Bart can commit all code on success or just udpates to the PRD on failure. This way BART can keep a record of failures until he returns SUCCESS

CLANCY should decide what to merge based on BART's success or failure. If BART succeeds, CLANCY should squash-merge the worktree back into main as a single commit with a comprehensive message. If BART fails, CLANCY can commit document updates for memory and just spawn another BART.


**INVESTIGATE**

- look at async-process to spawn commands with chdir
