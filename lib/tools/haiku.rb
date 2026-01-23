# frozen_string_literal: true

require_relative "../tool"

module Crayons
  module Tools
    class Haiku < Crayons::Tool
      HAIKU = <<~HAIKU
        Green code flows gently
        Tests pass, deployment completes
        Peace in the console
      HAIKU

      def name = "haiku"

      def description = "Generate a haiku poem"

      def params = []

      def call(_input = nil)
        { success: true, result: HAIKU.strip }
      end
    end
  end
end
