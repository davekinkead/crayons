# Crayons Architecture

/lib for code (everything in Crayons namespace)
  - tool.rb                → Crayons::Tool (base class)
  - errors.rb              → Crayons::ToolNotFoundError (exceptions)
  - tools.rb               → Crayons::Tools (factory module)
  - tools/
    - haiku.rb            → Crayons::Tools::Haiku (individual tool)
/spec for tests
