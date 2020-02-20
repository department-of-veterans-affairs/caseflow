# frozen_string_literal: true

class Contention
  attr_accessor :description

  def initialize(description)
    self.description = description
  end

  # BGS limits contention text to 255 bytes long, and free of newlines
  def text
    return unless description

    truncate(remove_newlines(description))
  end

  private

  def remove_newlines(description)
    description.gsub(/\s*[\r\n]+\s*/, " ")
  end

  def truncate(description)
    return description if description.bytesize <= 255

    trimmed = []
    description.split("").each do |char|
      break if trimmed.join("").bytesize >= 252

      trimmed << char
    end
    trimmed.pop if trimmed.join("").bytesize > 252
    "#{trimmed.join('')}..."
  end
end
