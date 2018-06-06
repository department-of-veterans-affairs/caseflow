class RampClosedAppeal < ApplicationRecord
  belongs_to :ramp_election

  delegate :established_at, to: :ramp_election

  def self.reclose_all!
    appeals_to_reclose = []

    find_in_batches(batch_size: 800) do |batch|
      appeals_to_reclose += AppealRepository.find_ramp_reopened_appeals(batch.map(&:vacols_id))
    end

    # TODO: actually close these once we verify everything is good.
    appeals_to_reclose
  end
end
