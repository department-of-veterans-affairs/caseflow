class Generators::Annotation
  extend Generators::Base

  class << self
    def build(attrs)
      attrs[:x] ||= 50
      attrs[:y] ||= 100
      attrs[:page] ||= 1

      Annotation.new(attrs || {})
    end
  end
end
