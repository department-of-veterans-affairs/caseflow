# frozen_string_literal: true

class Generators::EstablishClaim
  extend Generators::Base

  class << self
    def create(attrs = {})
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || Generators::LegacyAppeal.create.id
      attrs[:user_id] ||= attrs[:user].try(:id)

      EstablishClaim.create(attrs)
    end
  end
end
