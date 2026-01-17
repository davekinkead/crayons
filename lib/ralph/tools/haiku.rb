require_relative '../tool'

class Ralph::Tools::Haiku < Ralph::Tool
  description 'Generate a haiku poem'
  param :intensity, type: 'number', description: 'Intensity level of the haiku from 0.0 to 1.0', required: true

  # This tool exists purely for testing purposes
  def call(intensity: 1.0)
    <<~TEXT
      Seventeen slices,
      Fill the bottom of the bowl,
      Haiku word salad.
    TEXT
  end
end
