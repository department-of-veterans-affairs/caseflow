# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialze
      RequestStore[:current_user] = User.system_user
    end

    def seed!
      # place seed method calls here
    end

    private

    # place seed methods below
  end
end
