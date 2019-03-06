# frozen_string_literal: true

class HearingLocation < ApplicationRecord
  belongs_to :hearing, polymorphic: true
end
