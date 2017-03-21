class Generators::EstablishClaim
  extend Generators::Base

  class << self
    def create(attrs = {})
      attrs[:appeal_id] ||= Generators::Appeal.create.id
      EstablishClaim.create(attrs)
    end
  end
end
