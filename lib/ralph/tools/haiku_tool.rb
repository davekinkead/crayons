module Ralph
  class HaikuTool < RubyLLM::Tool
    description "Generate a haiku on a given topic"

    params do
      string :topic, description: "The topic for the haiku"
    end

    def execute(topic:)
      haikus = [
        "#{topic.split.first} shines bright,\nIn the morning light it glows,\nNature comes alive.",
        "#{topic.split.first} whispers soft,\nSecrets carried on the wind,\nDreams begin anew.",
        "In #{topic}'s embrace,\nTime stands still and hearts find peace,\nLove blooms endlessly."
      ]
      
      haikus.sample
    rescue => e
      { error: e.message }
    end
  end
end
