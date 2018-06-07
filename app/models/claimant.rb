class Claimant < ApplicationRecord
  belongs_to :review_claimant, polymorphic: true

  def self.create_from_intake_data!(data)
    create!(
      participant_id: data
    )
  end
end
