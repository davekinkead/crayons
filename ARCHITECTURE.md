# Architecture of Ralph

Ralph is a Ruby-based autonomous software development system that follows the Ralph Wiggum technique.

## Core Components

### Agents

`Agents` use a single agent.rb file to instantiate personas based on markdown files (see `agents/CODER.md`).
- load personas from markdown
- declare `Tool` use in frontmatter
- have their own context
- connect to LLM services via a `Client`

```
agent = Agent.new :coder
response = agent.call "instructions"
```

### Clients

`Clients` manage the LLM API infrastructure. They are simple extentions of RubyLLM

```
azure_client = RubyLLM.context do |config|
  config.openai_api_key = ENV['AZURE_KEY']
  config.openai_api_base = "https://azure.openai.azure.com"
  config.request_timeout = 180
end
```


### Tools

Tools are defined using the RubyLLM DSL.
