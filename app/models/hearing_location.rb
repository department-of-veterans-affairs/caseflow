class HearingLocation < ApplicationRecord
  belongs_to :hearing, polymorphic: true
end
