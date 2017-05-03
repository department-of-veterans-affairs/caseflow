class Generators::Tag
  extend Generators::Base

  class << self
    def build(attrs)
      attrs[:text] ||= "This is a tag"

      Tag.new(attrs || {})
    end
  end
end
