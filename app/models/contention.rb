# frozen_string_literal: true

class Contention
  attr_accessor :description

  def initialize(description)
    self.description = description
  end

  # BGS limits contention text to 255 bytes
  def text
    return unless description

    (description.bytesize > 255) ? truncated_description : description
  end

  private

  def truncated_description
    trimmed = []
    description.split("").each do |char|
      break if trimmed.join("").bytesize >= 252

      trimmed << char
    end
    trimmed.pop if trimmed.join("").bytesize > 252
    "#{trimmed.join('')}..."
  end
end
