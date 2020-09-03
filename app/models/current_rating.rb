# frozen_string_literal: true

class CurrentRating < Rating
  class << self
    def fetch_by_participant_id(participant_id)
      from_bgs_hash(BGSService.new.find_current_rating_profile_by_ptcpnt_id(participant_id))
    end

    def from_bgs_hash(data)
      new(
        participant_id: data[:ptcpnt_vet_id],
        profile_date: data[:prfl_dt],
        promulgation_date: data[:prmlgn_dt],
        rating_profile: data
      )
    end
  end
end
