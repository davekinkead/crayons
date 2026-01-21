Context Optimization Strategies from OpenCode

Tool Use Parallelization
- Batch tool (packages/opencode/src/tool/batch.ts:36) - Executes up to 10 tools in parallel
- System prompt encouragement - All tools explicitly instruct the LLM to make parallel calls when possible
- Proven 2-5x efficiency gain from batching independent operations
Context Window Management (Malloc-like)
Dynamic allocation/resizing (packages/opencode/src/session/compaction.ts:30-38):
- Checks if context exceeds usable limits: count > usable
- Calculates available tokens dynamically: usable = input.model.limit.input || context - output
- Protection zones: Keeps last 40k tokens safe (PRUNE_PROTECT = 40_000)
- Pruning threshold: Only compacts if can save 20k+ tokens (PRUNE_MINIMUM = 20_000)
Message History Trimming
Sliding window pruning (packages/opencode/src/session/compaction.ts:41-90):
- Reverse traversal erases old tool outputs
- Protects last 2 conversation turns
- Stops at existing compaction points
- Never compacts "skill" tool outputs
AI-powered compaction (packages/opencode/src/session/compaction.ts:92-193):
- LLM generates continuation prompt when context overflows
- Creates summary of what was done, files being worked on, next steps
- Old tool outputs marked with "[Old tool result content cleared]"
Tool Output Truncation
Global limits (packages/opencode/src/tool/truncation.ts:10-11):
- MAX_LINES: 2000
- MAX_BYTES: 50KB
Automatic wrapping (packages/opencode/src/tool/tool.ts:69-82):
- All tool outputs automatically truncated
- Full output saved to disk with filepath hint
- 7-day retention policy
Overflow detection (packages/opencode/src/session/processor.ts:274-276):
- Checks tokens after each completion
- Triggers auto-compaction on overflow
Token Optimization
- Cache read/write tracking for accurate usage monitoring
- Ignored/synthetic parts filtered before sending to model
- Output token limiting: max 32,000 tokens dynamically calculated
- Simple estimation: 4 characters ≈ 1 token
Summary: Context is dynamically allocated with protection zones, pruned using a sliding window approach, and automatically compacted via AI summarization when thresholds are exceeded—similar to malloc but with intelligent content-aware "freeing."
