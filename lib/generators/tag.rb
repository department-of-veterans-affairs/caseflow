# frozen_string_literal: true

class Generators::Tag
  extend Generators::Base

  class << self
    def build(attrs)
      attrs[:text] ||= "Default generated tag"

      Tag.new(attrs || {})
    end
  end
end
