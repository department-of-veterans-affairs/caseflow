class RampClosedAppeal < ApplicationRecord
  belongs_to :ramp_election

  delegate :established_at, to: :ramp_election
end
