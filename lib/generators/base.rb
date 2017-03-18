module Generators::Base
  def generate_external_id
    SecureRandom.hex[0..8]
  end

  def build(*)
    fail "#{self.class.name} must implement .build(attrs)"
  end

  def create(attrs = {})
    build(attrs).tap(&:save!)
  end
end
