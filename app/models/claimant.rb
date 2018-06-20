class Claimant < ApplicationRecord
  belongs_to :review_request, polymorphic: true

  def self.create_from_intake_data!(data)
    create!(
      participant_id: data
    )
  end
end
