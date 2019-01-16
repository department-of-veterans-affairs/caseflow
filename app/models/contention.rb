class Contention
  attr_accessor :description

  def initialize(description)
    self.description = description
  end

  # BGS limits contention text to 255 characters
  def text
    return unless description

    (description.length > 255) ? "#{description.slice(0, 252)}..." : description
  end
end
